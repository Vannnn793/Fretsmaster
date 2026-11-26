import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chord_detection_result.dart';
import '../entities/chord_guide.dart';
import '../entities/fretboard_context.dart';

abstract class ChordDetectionRepository {
  Future<Either<Failure, void>> initialize();
  Future<Either<Failure, ChordDetectionResult>> detectFromFrame({
    required CameraImage cameraImage,
    required int sensorOrientation,
  });
  void updateFretboardAnchor(FretboardAnchor anchor);
  Future<Either<Failure, List<ChordGuide>>> getChordGuides();
  Future<Either<Failure, ChordGuide>> getChordDetail(String name);
  void close();
}
