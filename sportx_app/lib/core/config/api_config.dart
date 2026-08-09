class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8002/api/v1';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 1;
}
