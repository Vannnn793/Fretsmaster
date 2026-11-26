import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Konfigurasi jangkar (anchor) fisik fretboard di layar kamera.
/// Memungkinkan proyeksi 2D terorientasi (translasi, rotasi, skala, dan mirror)
/// sehingga deteksi fret 1–5 dan senar 1–6 tetap akurat pada berbagai sudut pegangan gitar.
class FretboardAnchor extends Equatable {
  final double centerX; // 0.0 .. 1.0 (relatif terhadap lebar layar)
  final double centerY; // 0.0 .. 1.0 (relatif terhadap tinggi layar)
  final double width;   // Lebar area 6 senar (normalisasi layar)
  final double height;  // Panjang area fret 1–5 (normalisasi layar)
  final double angleRad; // Sudut kemiringan leher gitar (0 = vertikal)
  final bool mirrorStrings; // True jika kamera depan/selfie membalik arah senar 6 <-> 1
  final bool autoTrackNeck; // True jika jangkar otomatis mengikuti sumbu leher dari landmark tangan

  const FretboardAnchor({
    this.centerX = 0.50,
    this.centerY = 0.48,
    this.width = 0.72,
    this.height = 0.60,
    this.angleRad = 0.0,
    this.mirrorStrings = false,
    this.autoTrackNeck = false,
  });

  /// Preset vertikal standar (kamera menghadap lurus sepanjang leher gitar)
  factory FretboardAnchor.vertical({bool mirrorStrings = false}) {
    return FretboardAnchor(
      centerX: 0.50,
      centerY: 0.48,
      width: 0.72,
      height: 0.60,
      angleRad: 0.0,
      mirrorStrings: mirrorStrings,
    );
  }

  /// Preset miring alami (~35° seperti posisi bermain gitar normal)
  factory FretboardAnchor.angled({bool mirrorStrings = false}) {
    return FretboardAnchor(
      centerX: 0.50,
      centerY: 0.50,
      width: 0.56,
      height: 0.58,
      angleRad: -math.pi / 5.2, // ~ -34.6 derajat
      mirrorStrings: mirrorStrings,
    );
  }

  /// Preset horizontal (-90°: nut di kiri, fret 1–5 memanjang ke kanan)
  factory FretboardAnchor.horizontal({bool mirrorStrings = false}) {
    return FretboardAnchor(
      centerX: 0.50,
      centerY: 0.52,
      width: 0.44,
      height: 0.76,
      angleRad: -math.pi / 2,
      mirrorStrings: mirrorStrings,
    );
  }

  FretboardAnchor copyWith({
    double? centerX,
    double? centerY,
    double? width,
    double? height,
    double? angleRad,
    bool? mirrorStrings,
    bool? autoTrackNeck,
  }) {
    return FretboardAnchor(
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      width: width ?? this.width,
      height: height ?? this.height,
      angleRad: angleRad ?? this.angleRad,
      mirrorStrings: mirrorStrings ?? this.mirrorStrings,
      autoTrackNeck: autoTrackNeck ?? this.autoTrackNeck,
    );
  }

  @override
  List<Object?> get props => [
        centerX,
        centerY,
        width,
        height,
        angleRad,
        mirrorStrings,
        autoTrackNeck,
      ];
}

/// Posisi ujung jari yang terdeteksi di atas fretboard (fret 1–5 dan senar 1–6)
class FretboardFingertip extends Equatable {
  final String fingerName; // 'Telunjuk', 'Tengah', 'Manis', 'Kelingking'
  final int fingerId;     // 8 (index), 12 (middle), 16 (ring), 20 (pinky)
  final int fret;         // 1..5
  final int string;       // 1..6 (1 = High E, 6 = Low E)
  final double fretFloat;   // Koordinat kontinu fret (0.5 .. 5.5) untuk skor presisi
  final double stringFloat; // Koordinat kontinu senar (1.0 .. 6.0)
  final double x;           // Normalisasi layar 0.0 .. 1.0
  final double y;           // Normalisasi layar 0.0 .. 1.0
  final double confidence;  // 0.0 .. 1.0

  const FretboardFingertip({
    required this.fingerName,
    required this.fingerId,
    required this.fret,
    required this.string,
    double? fretFloat,
    double? stringFloat,
    required this.x,
    required this.y,
    this.confidence = 1.0,
  })  : fretFloat = fretFloat ?? fret * 1.0,
        stringFloat = stringFloat ?? string * 1.0;

  @override
  List<Object?> get props => [
        fingerName,
        fingerId,
        fret,
        string,
        fretFloat,
        stringFloat,
        x,
        y,
        confidence,
      ];
}

/// Hasil analisis konteks fretboard untuk memvalidasi posisi fisik jari di leher gitar
class FretboardDetectionContext extends Equatable {
  final List<FretboardFingertip> activeFingers;
  final Map<String, double> chordScores;
  final String primaryChord;
  final double primaryScore;
  final String fretboardSummary;
  final FretboardAnchor anchor;

  const FretboardDetectionContext({
    required this.activeFingers,
    required this.chordScores,
    required this.primaryChord,
    required this.primaryScore,
    required this.fretboardSummary,
    this.anchor = const FretboardAnchor(),
  });

  factory FretboardDetectionContext.empty({
    FretboardAnchor anchor = const FretboardAnchor(),
  }) {
    return FretboardDetectionContext(
      activeFingers: const [],
      chordScores: const {},
      primaryChord: '---',
      primaryScore: 0.0,
      fretboardSummary: 'Posisikan leher gitar di dalam kotak fretboard.',
      anchor: anchor,
    );
  }

  @override
  List<Object?> get props => [
        activeFingers,
        chordScores,
        primaryChord,
        primaryScore,
        fretboardSummary,
        anchor,
      ];
}
