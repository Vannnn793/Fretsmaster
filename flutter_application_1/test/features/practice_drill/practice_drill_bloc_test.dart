import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fretmaster/core/usecases/usecase.dart';
import 'package:fretmaster/features/practice_drill/domain/entities/practice_drill.dart';
import 'package:fretmaster/features/practice_drill/domain/repositories/practice_drill_repository.dart';
import 'package:fretmaster/features/practice_drill/domain/usecases/evaluate_transition_drill.dart';
import 'package:fretmaster/features/practice_drill/domain/usecases/get_drills.dart';
import 'package:fretmaster/features/practice_drill/domain/usecases/get_practice_logs.dart';
import 'package:fretmaster/features/practice_drill/domain/usecases/save_practice_log.dart';
import 'package:fretmaster/features/practice_drill/presentation/bloc/practice_drill_bloc.dart';
import 'package:fretmaster/features/practice_drill/presentation/bloc/practice_drill_event.dart';
import 'package:fretmaster/features/practice_drill/presentation/bloc/practice_drill_state.dart';

class MockPracticeDrillRepository extends Mock implements PracticeDrillRepository {}
class MockGetDrills extends Mock implements GetDrills {}
class MockGetPracticeLogs extends Mock implements GetPracticeLogs {}
class MockSavePracticeLog extends Mock implements SavePracticeLog {}
class MockEvaluateTransitionDrill extends Mock implements EvaluateTransitionDrill {}

void main() {
  late MockPracticeDrillRepository mockRepo;
  late MockGetDrills mockGetDrills;
  late MockGetPracticeLogs mockGetPracticeLogs;
  late MockSavePracticeLog mockSavePracticeLog;
  late MockEvaluateTransitionDrill mockEvaluateTransitionDrill;
  late PracticeDrillBloc bloc;

  final tDrill = const PracticeDrill(
    id: 1,
    title: 'Em -> G Basic',
    description: 'Transition test',
    chords: ['Em', 'G'],
    targetBpm: 60,
    difficulty: 'Pemula',
  );

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockRepo = MockPracticeDrillRepository();
    mockGetDrills = MockGetDrills();
    mockGetPracticeLogs = MockGetPracticeLogs();
    mockSavePracticeLog = MockSavePracticeLog();
    mockEvaluateTransitionDrill = MockEvaluateTransitionDrill();

    bloc = PracticeDrillBloc(
      repository: mockRepo,
      getDrills: mockGetDrills,
      getPracticeLogs: mockGetPracticeLogs,
      savePracticeLog: mockSavePracticeLog,
      evaluateTransitionDrill: mockEvaluateTransitionDrill,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('Initial state bernilai PracticeDrillInitial', () {
    expect(bloc.state, const PracticeDrillInitial());
  });

  blocTest<PracticeDrillBloc, PracticeDrillState>(
    'Emits [PracticeDrillLoading, PracticeDrillOverviewLoaded] ketika LoadDrillsAndHistory dipanggil',
    build: () {
      when(() => mockGetDrills(any())).thenAnswer((_) async => Right([tDrill]));
      when(() => mockGetPracticeLogs(any())).thenAnswer((_) async => const Right([]));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadDrillsAndHistory()),
    expect: () => [
      const PracticeDrillLoading(),
      isA<PracticeDrillOverviewLoaded>().having((s) => s.drills.length, 'drills.length', 1),
    ],
  );

  blocTest<PracticeDrillBloc, PracticeDrillState>(
    'Memulai sesi drill saat StartDrillSession dipanggil',
    build: () => bloc,
    act: (bloc) => bloc.add(StartDrillSession(tDrill)),
    expect: () => [
      isA<DrillSessionActive>()
          .having((s) => s.currentTargetChord, 'currentTargetChord', 'Em')
          .having((s) => s.nextChord, 'nextChord', 'G'),
    ],
  );
}
