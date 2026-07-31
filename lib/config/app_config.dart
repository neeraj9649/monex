import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const apiBaseUrl = _configuredApiBaseUrl == ''
      ? (kIsWeb ? '' : 'https://m.versai.in')
      : _configuredApiBaseUrl;
  static const allowLocalData = bool.fromEnvironment(
    'ALLOW_LOCAL_DATA',
    defaultValue: false,
  );

  static bool get hasApi => !allowLocalData;
}
