class ApiConfig{
  ApiConfig._();

  // 기본값은 배포 서버를 유지하고, 개발 시에만 --dart-define으로 덮어씁니다.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.34-50-57-207.sslip.io',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}