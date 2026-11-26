import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/practice_drill.dart';
import '../repositories/practice_drill_repository.dart';

class GetDrills implements UseCase<List<PracticeDrill>, NoParams> {
  final PracticeDrillRepository repository;

  GetDrills(this.repository);

  @override
  Future<Either<Failure, List<PracticeDrill>>> call(NoParams params) {
    return repository.getDrills();
  }
}
