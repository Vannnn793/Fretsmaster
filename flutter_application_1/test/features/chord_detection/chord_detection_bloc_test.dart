import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fretmaster/features/chord_detection/domain/entities/chord_guide.dart';
import 'package:fretmaster/features/chord_detection/domain/repositories/chord_detection_repository.dart';
import 'package:fretmaster/features/chord_detection/domain/usecases/detect_chord_from_frame.dart';
import 'package:fretmaster/features/chord_detection/presentation/bloc/chord_detection_bloc.dart';
import 'package:fretmaster/features/chord_detection/presentation/bloc/chord_detection_event.dart';
import 'package:fretmaster/features/chord_detection/presentation/bloc/chord_detection_state.dart';

class MockChordDetectionRepository extends Mock implements ChordDetectionRepository {}
class MockDetectChordFromFrame extends Mock implements DetectChordFromFrame {}

void main() {
  late MockChordDetectionRepository mockRepo;
  late MockDetectChordFromFrame mockDetectChord;
  late ChordDetectionBloc bloc;

  setUp(() {
    mockRepo = MockChordDetectionRepository();
    mockDetectChord = MockDetectChordFromFrame();

    bloc = ChordDetectionBloc(
      repository: mockRepo,
      detectChordFromFrame: mockDetectChord,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('Initial state bernilai ChordDetectionInitial', () {
    expect(bloc.state, const ChordDetectionInitial());
  });

  blocTest<ChordDetectionBloc, ChordDetectionState>(
    'Emits [ChordDetectionLoading, ChordDetectionReady] ketika inisialisasi model sukses',
    build: () {
      when(() => mockRepo.initialize()).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    act: (bloc) => bloc.add(const InitializeChordDetection()),
    expect: () => [
      const ChordDetectionLoading(),
      const ChordDetectionReady(),
    ],
  );

  blocTest<ChordDetectionBloc, ChordDetectionState>(
    'Mengubah target chord saat SetTargetChordGuide dipanggil',
    build: () => bloc,
    seed: () => const ChordDetectionReady(),
    act: (bloc) {
      const guide = ChordGuide(
        name: 'C',
        fullName: 'C Major',
        notes: 'C-E-G',
        frets: [-1, 3, 2, 0, 1, 0],
        fingers: [0, 3, 2, 0, 1, 0],
        difficulty: 'Mudah',
        tip: 'Tips',
        strum: 'Strum',
      );
      bloc.add(const SetTargetChordGuide(guide));
    },
    expect: () => [
      isA<ChordDetectionReady>().having((s) => s.targetChord?.name, 'targetChord.name', 'C'),
    ],
  );
}
