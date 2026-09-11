import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/auth_tokens.dart';
import '../model/auth_login_result.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> logout() async {
    await _apiClient.dio.post<void>(ApiEndpoints.logout);
  }

  Future<AuthTokens> refreshTokens(String refreshToken) async {
    if (refreshToken.trim().isEmpty) {
      throw ArgumentError('리프레시 토큰이 없습니다.');
    }

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.refresh,
      data: {'refresh': refreshToken},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('토큰 갱신 응답이 비어 있습니다.');
    }
    return AuthTokens.fromJson(data);
  }

  Future<AuthLoginResult> loginWithKakao({
    required String idToken,
    required String deviceId,
  }) async {
    if (idToken.trim().isEmpty) {
      throw ArgumentError('카카오 ID 토큰이 없습니다.');
    }
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.socialLogin,
      data: {
        'identity_type': 'KAKAO',
        'id_token': idToken,
        'device_id': deviceId,
        'device_name': 'Android Device',
        'platform': 'ANDROID',
      },
    );
    final data = response.data;
    if (data == null) throw const FormatException('로그인 응답이 비어 있습니다.');
    return AuthLoginResult.fromJson(data);
  }

  Future<AuthTokens> loginForDevelopment({required bool linkedPatient}) async {
    if (!kDebugMode) {
      throw StateError('개발용 로그인은 디버그 모드에서만 사용할 수 있습니다.');
    }

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      ApiEndpoints.socialLogin,
      data: {
        'identity_type': 'KAKAO',
        'identity_value': linkedPatient
            ? 'kakao_test_001'
            : 'flutter_new_patient_001',
        'device_id': linkedPatient
            ? 'flutter-test-device-01'
            : 'flutter-new-device-01',
        'device_name': 'Flutter Emulator',
        'platform': 'ANDROID',
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('로그인 응답이 비어 있습니다.');
    }

    return AuthTokens.fromJson(data);
  }
}
