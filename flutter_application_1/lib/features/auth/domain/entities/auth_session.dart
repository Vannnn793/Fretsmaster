import 'package:equatable/equatable.dart';
import 'user.dart';

class AuthSession extends Equatable {
  final User user;
  final String token;

  const AuthSession({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}
