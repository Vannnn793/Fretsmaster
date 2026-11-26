import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/practice_drill.dart';
import '../../domain/entities/practice_log.dart';
import '../../domain/repositories/practice_drill_repository.dart';
import '../datasources/practice_drill_remote_data_source.dart';
import '../models/practice_log_model.dart';

class PracticeDrillRepositoryImpl implements PracticeDrillRepository {
  final PracticeDrillRemoteDataSource remoteDataSource;

  PracticeDrillRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PracticeDrill>>> getDrills() async {
    try {
      final drills = await remoteDataSource.getDrills();
      return Right(drills);
    } catch (e) {
      return Left(ServerFailure('Gagal memuat paket latihan: $e'));
    }
  }

  @override
  Future<Either<Failure, PracticeDrill>> getDrillDetail(int id) async {
    try {
      final drill = await remoteDataSource.getDrillDetail(id);
      return Right(drill);
    } catch (e) {
      return Left(ServerFailure('Gagal memuat detail drill: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PracticeLog>>> getPracticeLogs() async {
    try {
      final logs = await remoteDataSource.getPracticeLogs();
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure('Gagal memuat riwayat latihan: $e'));
    }
  }

  @override
  Future<Either<Failure, PracticeLog>> savePracticeLog(PracticeLog log) async {
    try {
      final model = PracticeLogModel(
        drillId: log.drillId,
        chordName: log.chordName,
        accuracy: log.accuracy,
        bpm: log.bpm,
        durationSeconds: log.durationSeconds,
        notes: log.notes,
        createdAt: log.createdAt,
      );
      final saved = await remoteDataSource.savePracticeLog(model);
      return Right(saved);
    } catch (e) {
      return Left(ServerFailure('Gagal menyimpan sesi latihan: $e'));
    }
  }
}
