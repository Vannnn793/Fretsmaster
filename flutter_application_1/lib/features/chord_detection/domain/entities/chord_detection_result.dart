import 'package:equatable/equatable.dart';
import 'fretboard_context.dart';

enum HandFramingStatus {
  ok,
  noHandDetected,
  tooFar,
  tooClose,
  poorLightingOrBlur,
}

class ChordDetectionResult extends Equatable {
  final String chordName;
  final double confidence;
  final bool isChord;
  final Map<String, double> rawProbabilities;
  final List<dynamic> landmarks; // 21 HandJoint
  final HandFramingStatus framingStatus;
  final String positionHint;
  final double inferenceTimeMs;
  final DateTime timestamp;
  final FretboardDetectionContext? fretboardContext;

  const ChordDetectionResult({
    required this.chordName,
    required this.confidence,
    required this.isChord,
    required this.rawProbabilities,
    required this.landmarks,
    required this.framingStatus,
    required this.positionHint,
    required this.inferenceTimeMs,
    required this.timestamp,
    this.fretboardContext,
  });

  ChordDetectionResult copyWith({
    String? chordName,
    double? confidence,
    bool? isChord,
    Map<String, double>? rawProbabilities,
    List<dynamic>? landmarks,
    HandFramingStatus? framingStatus,
    String? positionHint,
    double? inferenceTimeMs,
    DateTime? timestamp,
    FretboardDetectionContext? fretboardContext,
  }) {
    return ChordDetectionResult(
      chordName: chordName ?? this.chordName,
      confidence: confidence ?? this.confidence,
      isChord: isChord ?? this.isChord,
      rawProbabilities: rawProbabilities ?? this.rawProbabilities,
      landmarks: landmarks ?? this.landmarks,
      framingStatus: framingStatus ?? this.framingStatus,
      positionHint: positionHint ?? this.positionHint,
      inferenceTimeMs: inferenceTimeMs ?? this.inferenceTimeMs,
      timestamp: timestamp ?? this.timestamp,
      fretboardContext: fretboardContext ?? this.fretboardContext,
    );
  }

  factory ChordDetectionResult.noHand({
    String hint = 'Posisikan tangan kiri menghadap kamera di area fret 1–5.',
  }) {
    return ChordDetectionResult(
      chordName: '---',
      confidence: 0.0,
      isChord: false,
      rawProbabilities: const {},
      landmarks: const [],
      framingStatus: HandFramingStatus.noHandDetected,
      positionHint: hint,
      inferenceTimeMs: 0.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        chordName,
        confidence,
        isChord,
        rawProbabilities,
        landmarks,
        framingStatus,
        positionHint,
        inferenceTimeMs,
        timestamp,
        fretboardContext,
      ];
}
