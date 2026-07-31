import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import 'secure_session_store.dart';

class ApiAuthStore {
  ApiAuthStore(this._sessionStore)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  final SecureSessionStore _sessionStore;
  final Dio _dio;

  Future<void> login({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    await _saveTokenFrom(response);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'companyName': companyName,
      },
    );
    await _saveTokenFrom(response);
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth/reset-password',
      data: {'token': token, 'password': password},
    );
  }

  Future<void> _saveTokenFrom(Response<Map<String, dynamic>> response) async {
    final token = response.data?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication failed: missing session token');
    }
    await _sessionStore.saveToken(token);
  }
}
