import 'package:equatable/equatable.dart';
import '../../domain/entities/chord_detection_result.dart';
import '../../domain/entities/chord_guide.dart';
import '../../domain/entities/fretboard_context.dart';

abstract class ChordDetectionState extends Equatable {
  const ChordDetectionState();

  @override
  List<Object?> get props => [];
}

class ChordDetectionInitial extends ChordDetectionState {
  const ChordDetectionInitial();
}

class ChordDetectionLoading extends ChordDetectionState {
  final String message;

  const ChordDetectionLoading({this.message = 'Memuat model AI MediaPipe Hands...'});

  @override
  List<Object?> get props => [message];
}

class ChordDetectionReady extends ChordDetectionState {
  final ChordDetectionResult? latestResult;
  final ChordGuide? targetChord;
  final int totalFramesProcessed;
  final bool isTargetMatched;
  final FretboardAnchor fretboardAnchor;

  const ChordDetectionReady({
    this.latestResult,
    this.targetChord,
    this.totalFramesProcessed = 0,
    this.isTargetMatched = false,
    this.fretboardAnchor = const FretboardAnchor(),
  });

  ChordDetectionReady copyWith({
    ChordDetectionResult? latestResult,
    ChordGuide? targetChord,
    int? totalFramesProcessed,
    bool? isTargetMatched,
    FretboardAnchor? fretboardAnchor,
  }) {
    return ChordDetectionReady(
      latestResult: latestResult ?? this.latestResult,
      targetChord: targetChord ?? this.targetChord,
      totalFramesProcessed: totalFramesProcessed ?? this.totalFramesProcessed,
      isTargetMatched: isTargetMatched ?? this.isTargetMatched,
      fretboardAnchor: fretboardAnchor ?? this.fretboardAnchor,
    );
  }

  @override
  List<Object?> get props => [
        latestResult,
        targetChord,
        totalFramesProcessed,
        isTargetMatched,
        fretboardAnchor,
      ];
}

class ChordDetectionFailureState extends ChordDetectionState {
  final String errorMessage;

  const ChordDetectionFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
