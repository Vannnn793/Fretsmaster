class ModelException implements Exception {
  final String message;
  ModelException(this.message);

  @override
  String toString() => 'ModelException: $message';
}

class InferenceException implements Exception {
  final String message;
  InferenceException(this.message);

  @override
  String toString() => 'InferenceException: $message';
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
