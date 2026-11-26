import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chord_guide.dart';
import '../../domain/entities/fretboard_context.dart';

abstract class ChordDetectionEvent extends Equatable {
  const ChordDetectionEvent();

  @override
  List<Object?> get props => [];
}

class InitializeChordDetection extends ChordDetectionEvent {
  const InitializeChordDetection();
}

class ProcessCameraFrame extends ChordDetectionEvent {
  final CameraImage image;
  final int sensorOrientation;

  const ProcessCameraFrame({
    required this.image,
    required this.sensorOrientation,
  });

  @override
  List<Object?> get props => [image, sensorOrientation];
}

class SetTargetChordGuide extends ChordDetectionEvent {
  final ChordGuide? targetChord;

  const SetTargetChordGuide(this.targetChord);

  @override
  List<Object?> get props => [targetChord];
}

class ToggleFlashlight extends ChordDetectionEvent {
  const ToggleFlashlight();
}

class UpdateFretboardAnchor extends ChordDetectionEvent {
  final FretboardAnchor anchor;

  const UpdateFretboardAnchor(this.anchor);

  @override
  List<Object?> get props => [anchor];
}

class ResetDetection extends ChordDetectionEvent {
  const ResetDetection();
}
