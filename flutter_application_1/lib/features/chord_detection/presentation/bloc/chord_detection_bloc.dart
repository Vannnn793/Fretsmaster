import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/frame_throttler.dart';
import '../../domain/repositories/chord_detection_repository.dart';
import '../../domain/usecases/detect_chord_from_frame.dart';
import 'chord_detection_event.dart';
import 'chord_detection_state.dart';

class ChordDetectionBloc extends Bloc<ChordDetectionEvent, ChordDetectionState> {
  final ChordDetectionRepository repository;
  final DetectChordFromFrame detectChordFromFrame;
  final FrameThrottler _throttler = FrameThrottler(
    throttleIntervalMs: AppConstants.defaultThrottleMs,
  );

  ChordDetectionBloc({
    required this.repository,
    required this.detectChordFromFrame,
  }) : super(const ChordDetectionInitial()) {
    on<InitializeChordDetection>(_onInitialize);
    on<ProcessCameraFrame>(_onProcessFrame, transformer: droppable());
    on<SetTargetChordGuide>(_onSetTargetChordGuide);
    on<UpdateFretboardAnchor>(_onUpdateFretboardAnchor);
    on<ResetDetection>(_onResetDetection);
  }

  Future<void> _onInitialize(
    InitializeChordDetection event,
    Emitter<ChordDetectionState> emit,
  ) async {
    emit(const ChordDetectionLoading());
    final result = await repository.initialize();
    result.fold(
      (failure) => emit(ChordDetectionFailureState(failure.message)),
      (_) => emit(const ChordDetectionReady()),
    );
  }

  Future<void> _onProcessFrame(
    ProcessCameraFrame event,
    Emitter<ChordDetectionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChordDetectionReady) return;

    if (!_throttler.shouldProcess()) {
      return;
    }
    _throttler.startProcessing();

    try {
      final resultEither = await detectChordFromFrame(
        DetectChordFromFrameParams(
          cameraImage: event.image,
          sensorOrientation: event.sensorOrientation,
        ),
      );

      resultEither.fold(
        (failure) {
          // Frame failure tidak menghentikan streaming
        },
        (detectionResult) {
          bool isMatched = false;
          if (currentState.targetChord != null && detectionResult.isChord) {
            isMatched = detectionResult.chordName.toLowerCase() ==
                currentState.targetChord!.name.toLowerCase();
          }

          final activeAnchor = detectionResult.fretboardContext?.anchor ?? currentState.fretboardAnchor;

          emit(currentState.copyWith(
            latestResult: detectionResult,
            totalFramesProcessed: currentState.totalFramesProcessed + 1,
            isTargetMatched: isMatched,
            fretboardAnchor: activeAnchor,
          ));
        },
      );
    } finally {
      _throttler.finishProcessing();
    }
  }

  void _onSetTargetChordGuide(
    SetTargetChordGuide event,
    Emitter<ChordDetectionState> emit,
  ) {
    if (state is ChordDetectionReady) {
      final ready = state as ChordDetectionReady;
      emit(ready.copyWith(targetChord: event.targetChord));
    }
  }

  void _onUpdateFretboardAnchor(
    UpdateFretboardAnchor event,
    Emitter<ChordDetectionState> emit,
  ) {
    repository.updateFretboardAnchor(event.anchor);
    if (state is ChordDetectionReady) {
      final ready = state as ChordDetectionReady;
      emit(ready.copyWith(fretboardAnchor: event.anchor));
    }
  }

  void _onResetDetection(
    ResetDetection event,
    Emitter<ChordDetectionState> emit,
  ) {
    _throttler.reset();
    if (state is ChordDetectionReady) {
      final ready = state as ChordDetectionReady;
      emit(ChordDetectionReady(
        targetChord: ready.targetChord,
        fretboardAnchor: ready.fretboardAnchor,
      ));
    }
  }

  @override
  Future<void> close() {
    repository.close();
    return super.close();
  }
}
