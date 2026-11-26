import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/practice_log.dart';
import '../repositories/practice_drill_repository.dart';

class GetPracticeLogs implements UseCase<List<PracticeLog>, NoParams> {
  final PracticeDrillRepository repository;

  GetPracticeLogs(this.repository);

  @override
  Future<Either<Failure, List<PracticeLog>>> call(NoParams params) {
    return repository.getPracticeLogs();
  }
}
