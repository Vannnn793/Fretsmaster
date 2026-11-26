import 'package:equatable/equatable.dart';

class HandJoint extends Equatable {
  final int id;
  final double x;
  final double y;
  final double z;

  const HandJoint({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  List<Object?> get props => [id, x, y, z];
}
