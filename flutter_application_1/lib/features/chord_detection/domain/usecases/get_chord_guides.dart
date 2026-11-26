import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chord_guide.dart';
import '../repositories/chord_detection_repository.dart';

class GetChordGuides implements UseCase<List<ChordGuide>, NoParams> {
  final ChordDetectionRepository repository;

  GetChordGuides(this.repository);

  @override
  Future<Either<Failure, List<ChordGuide>>> call(NoParams params) {
    return repository.getChordGuides();
  }
}
