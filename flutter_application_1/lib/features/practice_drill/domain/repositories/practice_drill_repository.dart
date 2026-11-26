import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/practice_drill.dart';
import '../entities/practice_log.dart';

abstract class PracticeDrillRepository {
  Future<Either<Failure, List<PracticeDrill>>> getDrills();
  Future<Either<Failure, PracticeDrill>> getDrillDetail(int id);
  Future<Either<Failure, List<PracticeLog>>> getPracticeLogs();
  Future<Either<Failure, PracticeLog>> savePracticeLog(PracticeLog log);
}
