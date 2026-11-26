import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/frame_converter.dart';
import '../../../../core/utils/temporal_smoother.dart';
import '../../domain/entities/chord_detection_result.dart';
import '../../domain/entities/fretboard_context.dart';
import '../../domain/entities/hand_joint.dart';
import '../../domain/services/chord_geometric_rule_engine.dart';
import '../../domain/services/fretboard_analyzer.dart';

abstract class TfliteMlpVisionDataSource {
  Future<void> initialize();
  Future<ChordDetectionResult> detectAndClassify({
    required CameraImage cameraImage,
    required int sensorOrientation,
  });
  void updateFretboardAnchor(FretboardAnchor anchor);
  FretboardAnchor get currentAnchor;
  void close();
}

/// Implementasi Pipeline 2-Tahap MediaPipe Hands + Lightweight MLP:
/// Tahap 1: Ekstraksi 21 koordinat sendi tangan 3D nyata secara langsung dari frame kamera via MediaPipe Hand Landmarker.
/// Tahap 2: Normalisasi spasial translasi & skala (invarian posisi & jarak).
/// Tahap 3: Klasifikasi akord presisi menggunakan MLP 63-fitur (chord_model.tflite) + Temporal Smoothing.
class TfliteMlpVisionDataSourceImpl implements TfliteMlpVisionDataSource {
  Interpreter? _landmarkInterpreter;
  Interpreter? _mlpInterpreter;
  Interpreter? _legacyVisionInterpreter;

  List<String> _labels = AppConstants.supportedChords;
  bool _isTwoStageActive = false;

  final TemporalSmoother _smoother = TemporalSmoother(windowSize: AppConstants.temporalWindowSize);
  final ChordGeometricRuleEngine _ruleEngine = const ChordGeometricRuleEngine();
  final FretboardAnalyzer _fretboardAnalyzer = const FretboardAnalyzer();
  FretboardAnchor _anchor = const FretboardAnchor();
  int _consecutiveNoHandFrames = 0;
  ChordDetectionResult? _lastValidResult;

  @override
  FretboardAnchor get currentAnchor => _anchor;

  @override
  void updateFretboardAnchor(FretboardAnchor anchor) {
    _anchor = anchor;
  }

  @override
  Future<void> initialize() async {
    if (_landmarkInterpreter != null && _mlpInterpreter != null) return;

    final options = InterpreterOptions()..threads = 2;

    // 1. Inisialisasi Pipeline 2-Stage (MediaPipe Hands + Lightweight MLP)
    try {
      _landmarkInterpreter = await Interpreter.fromAsset(
        AppConstants.modelHandLandmarkPath,
        options: options,
      );

      _mlpInterpreter = await Interpreter.fromAsset(
        AppConstants.modelTflitePath,
        options: options,
      );

      // Muat daftar label akord
      try {
        final labelsData = await rootBundle.loadString(AppConstants.modelLabelsPath);
        _labels = labelsData
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      } catch (_) {
        _labels = AppConstants.supportedChords;
      }

      _isTwoStageActive = true;
    } catch (_) {
      // 2. Fallback aman ke model citra kamera tunggal jika aset 2-stage belum termuat
      try {
        _legacyVisionInterpreter = await Interpreter.fromAsset(
          AppConstants.modelLegacyVisionPath,
          options: options,
        );
        _labels = ['A', 'Am', 'B', 'C', 'D', 'E', 'F', 'G'];
        _isTwoStageActive = false;
      } catch (e) {
        throw ModelException('Gagal memuat model TFLite AI: $e');
      }
    }
  }

  @override
  Future<ChordDetectionResult> detectAndClassify({
    required CameraImage cameraImage,
    required int sensorOrientation,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (_isTwoStageActive && _landmarkInterpreter != null && _mlpInterpreter != null) {
      return _runTwoStagePipeline(cameraImage, sensorOrientation, stopwatch);
    } else if (_legacyVisionInterpreter != null) {
      return _runLegacyVisionModel(cameraImage, sensorOrientation, stopwatch);
    } else {
      throw ModelException('Model AI belum diinisialisasi. Panggil initialize() terlebih dahulu.');
    }
  }

  /// Eksekusi Pipeline 2-Tahap MediaPipe Hand Landmark + MLP
  Future<ChordDetectionResult> _runTwoStagePipeline(
    CameraImage cameraImage,
    int sensorOrientation,
    Stopwatch stopwatch,
  ) async {
    // 1. Konversi frame kamera menjadi Float32 tensor [1, 224, 224, 3] dalam rentang [0.0, 1.0]
    final tensor = FrameConverter.yuv420ToFloat32Tensor(
      cameraImage,
      sensorOrientation,
      mode: PreprocessMode.normalized,
    );

    if (tensor == null) {
      return ChordDetectionResult.noHand(
        hint: 'Kamera sedang menyesuaikan resolusi frame. Pastikan kamera stabil.',
      );
    }

    final Uint8List inputBytes =
        tensor.buffer.asUint8List(tensor.offsetInBytes, tensor.lengthInBytes);

    // Output MediaPipe Hand Landmark TFLite:
    // Output 0 [1, 63]: 21 titik 3D landmarks (x, y, z dalam skala piksel 0..224)
    // Output 1 [1, 1]:  Hand presence score (0.0..1.0)
    // Output 2 [1, 1]:  Handedness score
    // Output 3 [1, 63]: World landmarks
    final landmarksOutput = [List<double>.filled(63, 0.0)];
    final presenceOutput = [List<double>.filled(1, 0.0)];
    final handednessOutput = [List<double>.filled(1, 0.0)];
    final worldLandmarksOutput = [List<double>.filled(63, 0.0)];

    final outputs = <int, Object>{
      0: landmarksOutput,
      1: presenceOutput,
      2: handednessOutput,
      3: worldLandmarksOutput,
    };

    _landmarkInterpreter!.runForMultipleInputs([inputBytes], outputs);

    final double handPresence = presenceOutput[0][0];

    // Toleransi hand presence dioptimalkan untuk tangan pada fret leher gitar (presence >= 0.20)
    if (handPresence < 0.20) {
      _consecutiveNoHandFrames++;
      // Hysteresis / graceful persistence: jangan langsung drop jika hanya hilang 1-3 frame
      if (_consecutiveNoHandFrames <= 3 && _lastValidResult != null && _lastValidResult!.isChord) {
        stopwatch.stop();
        return _lastValidResult!.copyWith(
          confidence: math.max(0.25, _lastValidResult!.confidence * 0.92),
          inferenceTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
          timestamp: DateTime.now(),
        );
      }

      _smoother.clear();
    _lastValidResult = null;
    _consecutiveNoHandFrames = 0;
      _lastValidResult = null;
      stopwatch.stop();
      return ChordDetectionResult.noHand(
        hint: 'Arahkan tangan kiri & leher gitar ke dalam kotak panduan fret 1–5.',
      );
    }

    _consecutiveNoHandFrames = 0;

    // 2. Ekstraksi 21 koordinat sendi tangan nyata dari MediaPipe
    final rawCoords = landmarksOutput[0];
    final joints = <HandJoint>[];
    for (int i = 0; i < 21; i++) {
      final px = rawCoords[i * 3];
      final py = rawCoords[i * 3 + 1];
      final pz = rawCoords[i * 3 + 2];

      // Normalisasi koordinat tampilan layar ke rentang [0.0, 1.0]
      final normX = (px / 224.0).clamp(0.0, 1.0);
      final normY = (py / 224.0).clamp(0.0, 1.0);
      final normZ = pz / 224.0;

      joints.add(HandJoint(id: i, x: normX, y: normY, z: normZ));
    }

    // 3. Normalisasi Spasial (Identik 100% dengan fungsi training Python di extract_landmarks.py):
    //    a. Translation Invariance: Geser titik acuan pergelangan tangan (wrist / index 0) ke (0, 0, 0)
    final wrist = joints[0];
    final translated = List.generate(21, (i) {
      return [
        joints[i].x - wrist.x,
        joints[i].y - wrist.y,
        joints[i].z - wrist.z,
      ];
    });

    //    b. Scale Invariance: Bagi semua koordinat dengan jarak wrist (0) ke pangkal jari tengah (9 / MCP)
    final mcp9 = translated[9];
    double scale = math.sqrt(mcp9[0] * mcp9[0] + mcp9[1] * mcp9[1] + mcp9[2] * mcp9[2]);
    if (scale < 1e-4) {
      double maxDist = 0.0;
      for (final t in translated) {
        final d = math.sqrt(t[0] * t[0] + t[1] * t[1] + t[2] * t[2]);
        if (d > maxDist) maxDist = d;
      }
      scale = maxDist;
    }
    if (scale < 1e-4) scale = 1.0;

    // Susun vektor 63-fitur terstandardisasi
    final features = List<double>.filled(63, 0.0);
    for (int i = 0; i < 21; i++) {
      features[i * 3] = translated[i][0] / scale;
      features[i * 3 + 1] = translated[i][1] / scale;
      features[i * 3 + 2] = translated[i][2] / scale;
    }

    // 4. Inferensi Klasifikasi Akord menggunakan MLP Ringan (chord_model.tflite)
    final chordOutput = [List<double>.filled(_labels.length, 0.0)];
    _mlpInterpreter!.run([features], chordOutput);

    final rawProbabilities = <String, double>{};
    for (int i = 0; i < _labels.length; i++) {
      rawProbabilities[_labels[i]] = chordOutput[0][i];
    }

    // 5. Evaluasi Aturan Geometris Biomekanika Jari (Pilar 2: Rule-Based Safety Guard)
    final geoEvaluation = _ruleEngine.evaluate(joints);

    // 6. Evaluasi Posisi Fisik pada Grid Fretboard Terorientasi (Pilar Fretboard Anchor)
    if (_anchor.autoTrackNeck) {
      _anchor = _fretboardAnalyzer.estimateAnchorFromHand(
        joints,
        currentAnchor: _anchor,
      );
    }
    final fretboardEvaluation = _fretboardAnalyzer.analyze(
      joints,
      anchor: _anchor,
    );

    // 7. Tri-Modal Fusion: Bobot AI (42%) + Geometri Biomekanika (23%) + Posisi Fisik Fretboard (35%)
    final fusedProbabilities = _ruleEngine.fuseWithMlProbabilities(
      rawProbabilities,
      geoEvaluation.ruleScores,
      fretboardScores: fretboardEvaluation.chordScores,
      mlWeight: 0.42,
      ruleWeight: 0.23,
      fretboardWeight: 0.35,
    );

    stopwatch.stop();

    // 8. Temporal Smoothing pada probabilitas hasil fusi (Moving average jendela N-frame agar anti-flicker)
    final topEntry = _smoother.getTopSmoothedChord(fusedProbabilities);
    final topChord = topEntry?.key ?? '---';
    final smoothedConfidence = topEntry?.value ?? 0.0;

    // Untuk klasifikasi 9-akord, peluang acak adalah 1/9 = 11.1%.
    // Probabilitas tersaring >= 25% menandakan akord dominan yang kuat.
    final isChordDetected = smoothedConfidence >= 0.25;
    final displayConfidence = math.min(1.0, smoothedConfidence * 1.35);

    String hint;
    HandFramingStatus framing;

    if (isChordDetected) {
      framing = HandFramingStatus.ok;
      final geoHint = geoEvaluation.diagnosticHint;
      hint = '${fretboardEvaluation.fretboardSummary} | $geoHint';
    } else {
      framing = HandFramingStatus.poorLightingOrBlur;
      hint = 'Posisikan jari di fret & senar sesuai diagram fretboard.';
    }

    final detectionResult = ChordDetectionResult(
      chordName: isChordDetected ? topChord : 'Mencari...',
      confidence: displayConfidence,
      isChord: isChordDetected,
      rawProbabilities: fusedProbabilities,
      landmarks: joints, // Koordinat 21 sendi nyata hasil MediaPipe
      framingStatus: framing,
      positionHint: hint,
      inferenceTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      timestamp: DateTime.now(),
      fretboardContext: fretboardEvaluation,
    );

    if (isChordDetected) {
      _lastValidResult = detectionResult;
    }

    return detectionResult;
  }

  /// Fallback inferensi model CNN langsung
  Future<ChordDetectionResult> _runLegacyVisionModel(
    CameraImage cameraImage,
    int sensorOrientation,
    Stopwatch stopwatch,
  ) async {
    final tensor = FrameConverter.yuv420ToFloat32Tensor(
      cameraImage,
      sensorOrientation,
      mode: PreprocessMode.normalized,
    );

    if (tensor == null) {
      return ChordDetectionResult.noHand(
        hint: 'Format frame kamera belum terbaca.',
      );
    }

    final Uint8List inputBytes =
        tensor.buffer.asUint8List(tensor.offsetInBytes, tensor.lengthInBytes);

    final output = [List<double>.filled(_labels.length, 0.0)];
    _legacyVisionInterpreter!.run(inputBytes, output);

    final probabilities = <String, double>{};
    for (int i = 0; i < _labels.length; i++) {
      probabilities[_labels[i]] = output[0][i];
    }

    stopwatch.stop();

    final topEntry = _smoother.getTopSmoothedChord(probabilities);
    final topChord = topEntry?.key ?? '---';
    final rawConfidence = topEntry?.value ?? 0.0;
    final isChordDetected = rawConfidence >= 0.35;

    final joints = generateChordLandmarks(isChordDetected ? topChord : 'C');

    return ChordDetectionResult(
      chordName: isChordDetected ? topChord : 'Mencari...',
      confidence: math.min(1.0, rawConfidence * 1.2),
      isChord: isChordDetected,
      rawProbabilities: probabilities,
      landmarks: joints,
      framingStatus: isChordDetected ? HandFramingStatus.ok : HandFramingStatus.poorLightingOrBlur,
      positionHint: isChordDetected
          ? 'Penjarian akord $topChord terdeteksi.'
          : 'Arahkan tangan kiri ke dalam kotak panduan.',
      inferenceTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      timestamp: DateTime.now(),
    );
  }

  /// Template landmark geometris jari untuk visualisasi fallback/diagram
  List<HandJoint> generateChordLandmarks(String chord) {
    final joints = <HandJoint>[];
    const baseCenterX = 0.50;
    const baseCenterY = 0.65;

    // 0: Wrist
    joints.add(const HandJoint(id: 0, x: baseCenterX, y: baseCenterY + 0.20, z: 0.0));
    // 1-4: Thumb
    joints.add(const HandJoint(id: 1, x: baseCenterX - 0.08, y: baseCenterY + 0.10, z: -0.05));
    joints.add(const HandJoint(id: 2, x: baseCenterX - 0.14, y: baseCenterY + 0.02, z: -0.08));
    joints.add(const HandJoint(id: 3, x: baseCenterX - 0.18, y: baseCenterY - 0.06, z: -0.10));
    joints.add(const HandJoint(id: 4, x: baseCenterX - 0.20, y: baseCenterY - 0.14, z: -0.12));

    double idxOffX = -0.06, idxOffY = -0.20;
    double midOffX = 0.00, midOffY = -0.26;
    double rngOffX = 0.06, rngOffY = -0.32;
    double pnkOffX = 0.12, pnkOffY = -0.18;

    switch (chord.toUpperCase()) {
      case 'C':
        idxOffX = -0.06; idxOffY = -0.20;
        midOffX = 0.00;  midOffY = -0.26;
        rngOffX = 0.06;  rngOffY = -0.32;
        break;
      case 'A':
        idxOffX = 0.02;  idxOffY = -0.25;
        midOffX = 0.00;  midOffY = -0.23;
        rngOffX = -0.02; rngOffY = -0.21;
        break;
      case 'AM':
        idxOffX = -0.05; idxOffY = -0.20;
        midOffX = 0.01;  midOffY = -0.26;
        rngOffX = -0.01; rngOffY = -0.24;
        break;
      case 'G':
        midOffX = 0.06;  midOffY = -0.34;
        idxOffX = 0.03;  idxOffY = -0.27;
        rngOffX = -0.06; rngOffY = -0.20;
        pnkOffX = -0.07; pnkOffY = -0.20;
        break;
      case 'E':
        idxOffX = -0.02; idxOffY = -0.21;
        midOffX = 0.04;  midOffY = -0.26;
        rngOffX = 0.02;  rngOffY = -0.25;
        break;
      case 'EM':
        idxOffX = -0.05; idxOffY = -0.15;
        midOffX = 0.04;  midOffY = -0.26;
        rngOffX = 0.02;  rngOffY = -0.25;
        break;
      case 'D':
        idxOffX = 0.00;  idxOffY = -0.24;
        midOffX = -0.06; midOffY = -0.22;
        rngOffX = -0.03; rngOffY = -0.28;
        break;
      case 'DM':
        idxOffX = 0.03;  idxOffY = -0.18; // Senar 1 Fret 1
        midOffX = -0.03; midOffY = -0.23; // Senar 3 Fret 2
        rngOffX = 0.00;  rngOffY = -0.27; // Senar 2 Fret 3
        break;
      case 'F':
        idxOffX = -0.06; idxOffY = -0.15; // Barre Fret 1
        midOffX = -0.02; midOffY = -0.22; // Senar 3 Fret 2
        rngOffX = 0.04;  rngOffY = -0.28; // Senar 5 Fret 3
        pnkOffX = 0.04;  pnkOffY = -0.25; // Senar 4 Fret 3
        break;
      case 'B':
        idxOffX = -0.04; idxOffY = -0.22; // Senar 5 Fret 2
        midOffX = 0.04;  midOffY = -0.28; // Senar 4 Fret 4
        rngOffX = 0.04;  rngOffY = -0.26; // Senar 3 Fret 4
        pnkOffX = 0.04;  pnkOffY = -0.24; // Senar 2 Fret 4
        break;
    }

    joints.add(const HandJoint(id: 5, x: baseCenterX - 0.05, y: baseCenterY, z: 0.02));
    joints.add(const HandJoint(id: 6, x: baseCenterX - 0.06, y: baseCenterY - 0.10, z: 0.05));
    joints.add(const HandJoint(id: 7, x: baseCenterX - 0.07, y: baseCenterY - 0.18, z: 0.06));
    joints.add(HandJoint(id: 8, x: baseCenterX + idxOffX, y: baseCenterY + idxOffY, z: 0.07));

    joints.add(const HandJoint(id: 9, x: baseCenterX, y: baseCenterY - 0.02, z: 0.02));
    joints.add(const HandJoint(id: 10, x: baseCenterX, y: baseCenterY - 0.12, z: 0.05));
    joints.add(const HandJoint(id: 11, x: baseCenterX, y: baseCenterY - 0.20, z: 0.06));
    joints.add(HandJoint(id: 12, x: baseCenterX + midOffX, y: baseCenterY + midOffY, z: 0.07));

    joints.add(const HandJoint(id: 13, x: baseCenterX + 0.05, y: baseCenterY, z: 0.01));
    joints.add(const HandJoint(id: 14, x: baseCenterX + 0.06, y: baseCenterY - 0.10, z: 0.04));
    joints.add(const HandJoint(id: 15, x: baseCenterX + 0.07, y: baseCenterY - 0.18, z: 0.05));
    joints.add(HandJoint(id: 16, x: baseCenterX + rngOffX, y: baseCenterY + rngOffY, z: 0.06));

    joints.add(const HandJoint(id: 17, x: baseCenterX + 0.10, y: baseCenterY + 0.04, z: 0.0));
    joints.add(const HandJoint(id: 18, x: baseCenterX + 0.12, y: baseCenterY - 0.04, z: 0.02));
    joints.add(const HandJoint(id: 19, x: baseCenterX + 0.13, y: baseCenterY - 0.12, z: 0.03));
    joints.add(HandJoint(id: 20, x: baseCenterX + pnkOffX, y: baseCenterY + pnkOffY, z: 0.04));

    return joints;
  }

  @override
  void close() {
    _landmarkInterpreter?.close();
    _landmarkInterpreter = null;
    _mlpInterpreter?.close();
    _mlpInterpreter = null;
    _legacyVisionInterpreter?.close();
    _legacyVisionInterpreter = null;
    _smoother.clear();
    _lastValidResult = null;
    _consecutiveNoHandFrames = 0;
  }
}
