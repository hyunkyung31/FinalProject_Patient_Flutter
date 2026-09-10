class ApiConfig{
  ApiConfig._();

  static const String baseUrl = "https://api.34-50-57-207.sslip.io";

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}