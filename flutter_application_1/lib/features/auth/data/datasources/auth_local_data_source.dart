import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheSession(AuthSessionModel session);
  Future<AuthSessionModel?> getSavedSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const _kAuthToken = 'fretmaster_auth_token';
  static const _kAuthUser = 'fretmaster_auth_user';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheSession(AuthSessionModel session) async {
    await sharedPreferences.setString(_kAuthToken, session.token);
    await sharedPreferences.setString(
      _kAuthUser,
      jsonEncode((session.user as UserModel).toJson()),
    );
  }

  @override
  Future<AuthSessionModel?> getSavedSession() async {
    final token = sharedPreferences.getString(_kAuthToken);
    final userJson = sharedPreferences.getString(_kAuthUser);

    if (token == null || token.isEmpty || userJson == null || userJson.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(userJson);
      final user = UserModel.fromJson(decoded);
      return AuthSessionModel(user: user, token: token);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await sharedPreferences.remove(_kAuthToken);
    await sharedPreferences.remove(_kAuthUser);
  }
}
