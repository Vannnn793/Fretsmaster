import 'package:equatable/equatable.dart';
import '../../domain/entities/practice_drill.dart';

abstract class PracticeDrillEvent extends Equatable {
  const PracticeDrillEvent();

  @override
  List<Object?> get props => [];
}

class LoadDrillsAndHistory extends PracticeDrillEvent {
  const LoadDrillsAndHistory();
}

class StartDrillSession extends PracticeDrillEvent {
  final PracticeDrill drill;

  const StartDrillSession(this.drill);

  @override
  List<Object?> get props => [drill];
}

class TickDrillBeat extends PracticeDrillEvent {
  const TickDrillBeat();
}

class RecordChordTransition extends PracticeDrillEvent {
  final String detectedChord;
  final double confidence;

  const RecordChordTransition({
    required this.detectedChord,
    required this.confidence,
  });

  @override
  List<Object?> get props => [detectedChord, confidence];
}

class FinishDrillSession extends PracticeDrillEvent {
  const FinishDrillSession();
}
