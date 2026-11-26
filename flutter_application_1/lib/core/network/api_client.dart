import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Client HTTP terpusat untuk komunikasi dengan Laravel REST API FretMaster.
class ApiClient {
  final http.Client client;
  final SharedPreferences prefs;

  ApiClient({
    required this.client,
    required this.prefs,
  });

  String get baseUrl {
    return prefs.getString(AppConstants.keyApiBaseUrl) ?? AppConstants.defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    await prefs.setString(AppConstants.keyApiBaseUrl, url);
  }

  String? get token {
    return prefs.getString(AppConstants.keyAuthToken);
  }

  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth && token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, bool auth = true}) async {
    try {
      var uriString = '$baseUrl$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        uriString += '?$query';
      }
      final uri = Uri.parse(uriString);
      final response = await client
          .get(uri, headers: _buildHeaders(includeAuth: auth))
          .timeout(const Duration(seconds: 12));

      return _processResponse(response);
    } on SocketException catch (e) {
      throw ServerException('Koneksi ke backend server gagal: ${e.message}');
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Gagal memproses request GET: $e');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool auth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await client
          .post(
            uri,
            headers: _buildHeaders(includeAuth: auth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));

      return _processResponse(response);
    } on SocketException catch (e) {
      throw ServerException('Koneksi ke backend server gagal: ${e.message}');
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Gagal memproses request POST: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      json = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    } else if (response.statusCode == 401) {
      throw AuthException(json is Map && json['message'] != null
          ? json['message'] as String
          : 'Sesi login telah kedaluwarsa.');
    } else {
      final message = json is Map && json['message'] != null
          ? json['message'] as String
          : 'Terjadi kesalahan pada server (HTTP ${response.statusCode})';
      throw ServerException(message);
    }
  }
}
