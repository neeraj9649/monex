import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  static const _tokenKey = 'founder_finance.auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
