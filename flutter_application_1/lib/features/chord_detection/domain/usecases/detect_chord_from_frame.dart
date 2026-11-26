import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chord_detection_result.dart';
import '../repositories/chord_detection_repository.dart';

class DetectChordFromFrameParams {
  final CameraImage cameraImage;
  final int sensorOrientation;

  const DetectChordFromFrameParams({
    required this.cameraImage,
    required this.sensorOrientation,
  });
}

class DetectChordFromFrame implements UseCase<ChordDetectionResult, DetectChordFromFrameParams> {
  final ChordDetectionRepository repository;

  DetectChordFromFrame(this.repository);

  @override
  Future<Either<Failure, ChordDetectionResult>> call(DetectChordFromFrameParams params) {
    return repository.detectFromFrame(
      cameraImage: params.cameraImage,
      sensorOrientation: params.sensorOrientation,
    );
  }
}
