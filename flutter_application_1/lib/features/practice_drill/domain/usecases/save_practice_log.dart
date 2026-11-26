import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/practice_log.dart';
import '../repositories/practice_drill_repository.dart';

class SavePracticeLog implements UseCase<PracticeLog, PracticeLog> {
  final PracticeDrillRepository repository;

  SavePracticeLog(this.repository);

  @override
  Future<Either<Failure, PracticeLog>> call(PracticeLog params) {
    return repository.savePracticeLog(params);
  }
}
