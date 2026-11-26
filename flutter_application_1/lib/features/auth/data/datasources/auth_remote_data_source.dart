import '../../../../core/network/api_client.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<void> logout(String token);

  Future<UserModel> getProfile(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({
    required this.apiClient,
  });

  @override
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await apiClient.post(
      '/register',
      auth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return AuthSessionModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Respons registrasi tidak valid.');
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/login',
      auth: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return AuthSessionModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Respons login tidak valid.');
  }

  @override
  Future<void> logout(String token) async {
    await apiClient.post('/logout', auth: true);
  }

  @override
  Future<UserModel> getProfile(String token) async {
    final response = await apiClient.get('/user', auth: true);
    if (response is Map<String, dynamic> && response['data'] != null) {
      return UserModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Gagal memuat profil pengguna.');
  }
}
