import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ModelLoadFailure extends Failure {
  const ModelLoadFailure(super.message);
}

class InferenceFailure extends Failure {
  const InferenceFailure(super.message);
}

class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
