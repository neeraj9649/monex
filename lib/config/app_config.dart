class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const useApi = bool.fromEnvironment('USE_API', defaultValue: false);

  static bool get hasApi => useApi;
}
