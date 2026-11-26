import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/practice_log.dart';
import '../../domain/repositories/practice_drill_repository.dart';
import '../../domain/usecases/evaluate_transition_drill.dart';
import '../../domain/usecases/get_drills.dart';
import '../../domain/usecases/get_practice_logs.dart';
import '../../domain/usecases/save_practice_log.dart';
import 'practice_drill_event.dart';
import 'practice_drill_state.dart';
import '../../../../core/usecases/usecase.dart';

class PracticeDrillBloc extends Bloc<PracticeDrillEvent, PracticeDrillState> {
  final PracticeDrillRepository repository;
  final GetDrills getDrills;
  final GetPracticeLogs getPracticeLogs;
  final SavePracticeLog savePracticeLog;
  final EvaluateTransitionDrill evaluateTransitionDrill;

  Timer? _metronomeTimer;
  Timer? _elapsedTimer;
  DateTime _lastTransitionTime = DateTime.now();

  PracticeDrillBloc({
    required this.repository,
    required this.getDrills,
    required this.getPracticeLogs,
    required this.savePracticeLog,
    required this.evaluateTransitionDrill,
  }) : super(const PracticeDrillInitial()) {
    on<LoadDrillsAndHistory>(_onLoadOverview);
    on<StartDrillSession>(_onStartSession);
    on<TickDrillBeat>(_onTickBeat);
    on<RecordChordTransition>(_onRecordTransition);
    on<FinishDrillSession>(_onFinishSession);
  }

  Future<void> _onLoadOverview(
    LoadDrillsAndHistory event,
    Emitter<PracticeDrillState> emit,
  ) async {
    emit(const PracticeDrillLoading());
    final drillsEither = await getDrills(NoParams());
    final logsEither = await getPracticeLogs(NoParams());

    drillsEither.fold(
      (failure) => emit(PracticeDrillError(failure.message)),
      (drills) {
        logsEither.fold(
          (failure) => emit(PracticeDrillOverviewLoaded(drills: drills, historyLogs: const [])),
          (logs) => emit(PracticeDrillOverviewLoaded(drills: drills, historyLogs: logs)),
        );
      },
    );
  }

  void _onStartSession(
    StartDrillSession event,
    Emitter<PracticeDrillState> emit,
  ) {
    _metronomeTimer?.cancel();
    _elapsedTimer?.cancel();

    _lastTransitionTime = DateTime.now();

    emit(DrillSessionActive(
      drill: event.drill,
      currentChordIndex: 0,
      totalChordsInCycle: event.drill.chords.length,
      currentBeat: 1,
    ));

    // Beat interval: (60 / BPM) * 1000 ms
    final beatIntervalMs = (60000 / event.drill.targetBpm).round();
    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: beatIntervalMs),
      (_) => add(const TickDrillBeat()),
    );

    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        final current = state;
        if (current is DrillSessionActive) {
          emit(current.copyWith(elapsedSeconds: current.elapsedSeconds + 1));
        }
      },
    );
  }

  void _onTickBeat(
    TickDrillBeat event,
    Emitter<PracticeDrillState> emit,
  ) {
    final current = state;
    if (current is! DrillSessionActive) return;

    final nextBeat = (current.currentBeat % 4) + 1;
    int nextChordIndex = current.currentChordIndex;

    // Setiap bar (setelah beat 4 kembali ke beat 1), pindah ke chord selanjutnya dalam rangkaian
    if (nextBeat == 1) {
      nextChordIndex = (current.currentChordIndex + 1) % current.drill.chords.length;
    }

    emit(current.copyWith(
      currentBeat: nextBeat,
      currentChordIndex: nextChordIndex,
    ));
  }

  Future<void> _onRecordTransition(
    RecordChordTransition event,
    Emitter<PracticeDrillState> emit,
  ) async {
    final current = state;
    if (current is! DrillSessionActive) return;

    final now = DateTime.now();
    final durationMs = now.difference(_lastTransitionTime).inMilliseconds.toDouble();
    _lastTransitionTime = now;

    final evalResult = await evaluateTransitionDrill(
      EvaluateTransitionParams(
        targetChord: current.currentTargetChord,
        detectedChord: event.detectedChord,
        confidence: event.confidence,
        transitionDurationMs: durationMs,
        targetBpm: current.drill.targetBpm,
      ),
    );

    evalResult.fold(
      (_) {},
      (result) {
        final newSuccess = current.successfulTransitions + (result.isSuccessful ? 1 : 0);
        final newTotal = current.completedTransitions + 1;
        final newCumulativeAcc = current.cumulativeAccuracy + result.accuracyScore;

        emit(current.copyWith(
          completedTransitions: newTotal,
          successfulTransitions: newSuccess,
          cumulativeAccuracy: newCumulativeAcc,
        ));
      },
    );
  }

  Future<void> _onFinishSession(
    FinishDrillSession event,
    Emitter<PracticeDrillState> emit,
  ) async {
    _metronomeTimer?.cancel();
    _elapsedTimer?.cancel();

    final current = state;
    if (current is! DrillSessionActive) return;

    final finalAccuracy = current.currentAccuracyPercent;

    final logToSave = PracticeLog(
      drillId: current.drill.id,
      drillTitle: current.drill.title,
      accuracy: finalAccuracy,
      bpm: current.drill.targetBpm,
      durationSeconds: current.elapsedSeconds > 0 ? current.elapsedSeconds : 1,
      notes: 'Latihan transisi ${current.drill.chords.join(" ➔ ")} (${current.successfulTransitions}/${current.completedTransitions} transisi tepat).',
      createdAt: DateTime.now(),
    );

    emit(const PracticeDrillLoading());

    final saveResult = await savePracticeLog(logToSave);
    saveResult.fold(
      (failure) => emit(PracticeDrillError('Gagal menyimpan sesi latihan: ${failure.message}')),
      (saved) => emit(DrillSessionCompleted(savedLog: saved)),
    );
  }

  @override
  Future<void> close() {
    _metronomeTimer?.cancel();
    _elapsedTimer?.cancel();
    return super.close();
  }
}
