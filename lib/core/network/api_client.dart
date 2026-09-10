import 'package:dio/dio.dart';

import '../config/api_config.dart';

class ApiClient {
  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio dio;

  // 로그인 성공 후 받은 Access Token 설정
  void setAccessToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // 로그아웃 시 인증 정보 제거
  void clearAccessToken() {
    dio.options.headers.remove('Authorization');
  }

  void dispose() {
    dio.close();
  }
}