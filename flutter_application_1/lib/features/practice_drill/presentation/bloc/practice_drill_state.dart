import 'package:equatable/equatable.dart';
import '../../domain/entities/practice_drill.dart';
import '../../domain/entities/practice_log.dart';

abstract class PracticeDrillState extends Equatable {
  const PracticeDrillState();

  @override
  List<Object?> get props => [];
}

class PracticeDrillInitial extends PracticeDrillState {
  const PracticeDrillInitial();
}

class PracticeDrillLoading extends PracticeDrillState {
  const PracticeDrillLoading();
}

class PracticeDrillOverviewLoaded extends PracticeDrillState {
  final List<PracticeDrill> drills;
  final List<PracticeLog> historyLogs;

  const PracticeDrillOverviewLoaded({
    required this.drills,
    required this.historyLogs,
  });

  @override
  List<Object?> get props => [drills, historyLogs];
}

class DrillSessionActive extends PracticeDrillState {
  final PracticeDrill drill;
  final int currentChordIndex;
  final int totalChordsInCycle;
  final int currentBeat; // 1, 2, 3, 4
  final int completedTransitions;
  final int successfulTransitions;
  final double cumulativeAccuracy;
  final int elapsedSeconds;

  const DrillSessionActive({
    required this.drill,
    required this.currentChordIndex,
    required this.totalChordsInCycle,
    this.currentBeat = 1,
    this.completedTransitions = 0,
    this.successfulTransitions = 0,
    this.cumulativeAccuracy = 0.0,
    this.elapsedSeconds = 0,
  });

  String get currentTargetChord => drill.chords[currentChordIndex % drill.chords.length];
  String get nextChord => drill.chords[(currentChordIndex + 1) % drill.chords.length];

  double get currentAccuracyPercent =>
      completedTransitions > 0 ? (cumulativeAccuracy / completedTransitions) : 0.0;

  DrillSessionActive copyWith({
    int? currentChordIndex,
    int? currentBeat,
    int? completedTransitions,
    int? successfulTransitions,
    double? cumulativeAccuracy,
    int? elapsedSeconds,
  }) {
    return DrillSessionActive(
      drill: drill,
      currentChordIndex: currentChordIndex ?? this.currentChordIndex,
      totalChordsInCycle: totalChordsInCycle,
      currentBeat: currentBeat ?? this.currentBeat,
      completedTransitions: completedTransitions ?? this.completedTransitions,
      successfulTransitions: successfulTransitions ?? this.successfulTransitions,
      cumulativeAccuracy: cumulativeAccuracy ?? this.cumulativeAccuracy,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  @override
  List<Object?> get props => [
        drill,
        currentChordIndex,
        totalChordsInCycle,
        currentBeat,
        completedTransitions,
        successfulTransitions,
        cumulativeAccuracy,
        elapsedSeconds,
      ];
}

class DrillSessionCompleted extends PracticeDrillState {
  final PracticeLog savedLog;

  const DrillSessionCompleted({required this.savedLog});

  @override
  List<Object?> get props => [savedLog];
}

class PracticeDrillError extends PracticeDrillState {
  final String message;

  const PracticeDrillError(this.message);

  @override
  List<Object?> get props => [message];
}
