import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chord_detection_result.dart';
import '../../domain/entities/chord_guide.dart';
import '../../domain/entities/fretboard_context.dart';
import '../../domain/repositories/chord_detection_repository.dart';
import '../datasources/chord_detection_remote_data_source.dart';
import '../datasources/tflite_mlp_vision_data_source.dart';

class ChordDetectionRepositoryImpl implements ChordDetectionRepository {
  final TfliteMlpVisionDataSource visionDataSource;
  final ChordDetectionRemoteDataSource remoteDataSource;

  ChordDetectionRepositoryImpl({
    required this.visionDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      await visionDataSource.initialize();
      return const Right(null);
    } catch (e) {
      return Left(ModelLoadFailure('Gagal inisialisasi model MediaPipe MLP: $e'));
    }
  }

  @override
  Future<Either<Failure, ChordDetectionResult>> detectFromFrame({
    required CameraImage cameraImage,
    required int sensorOrientation,
  }) async {
    try {
      final result = await visionDataSource.detectAndClassify(
        cameraImage: cameraImage,
        sensorOrientation: sensorOrientation,
      );
      return Right(result);
    } catch (e) {
      return Left(InferenceFailure('Gagal mendeteksi chord: $e'));
    }
  }

  @override
  void updateFretboardAnchor(FretboardAnchor anchor) {
    visionDataSource.updateFretboardAnchor(anchor);
  }

  @override
  Future<Either<Failure, List<ChordGuide>>> getChordGuides() async {
    try {
      final guides = await remoteDataSource.getChordGuides();
      return Right(guides);
    } catch (e) {
      return Left(ServerFailure('Gagal mengambil daftar chord: $e'));
    }
  }

  @override
  Future<Either<Failure, ChordGuide>> getChordDetail(String name) async {
    try {
      final guide = await remoteDataSource.getChordDetail(name);
      return Right(guide);
    } catch (e) {
      return Left(ServerFailure('Gagal mengambil detail chord: $e'));
    }
  }

  @override
  void close() {
    visionDataSource.close();
  }
}
