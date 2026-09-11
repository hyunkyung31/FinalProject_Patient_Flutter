import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_endpoints.dart';
import '../service/auth_service.dart';
import '../model/auth_login_result.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required this.tokenStorage})
    : _apiClient = apiClient,
      _authService = AuthService(apiClient);

  final ApiClient _apiClient;
  final TokenStorage tokenStorage;
  final AuthService _authService;

  Future<void> logout() async {
    try {
      await _authService.logout();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      // 액세스 토큰만 만료됐다면 갱신 후 서버 세션 종료를 다시 요청합니다.
      try {
        if (await restoreSession()) await _authService.logout();
      } on DioException catch (refreshError) {
        if (refreshError.response?.statusCode != 401) rethrow;
        // 갱신도 거부된 세션은 로컬 인증 정보를 제거합니다.
      }
    }
    await clearSession();
  }

  Future<bool> hasPatientLink() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.myLinkStatus,
    );
    final linked = response.data?['linked'];
    if (linked is! bool) {
      throw const FormatException('병원기록 연결 상태를 확인할 수 없습니다.');
    }
    return linked;
  }

  Future<void> clearSession() async {
    _apiClient.clearAccessToken();
    await tokenStorage.clearTokens();
  }

  Future<bool> restoreSession() async {
    _apiClient.clearAccessToken();
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.trim().isEmpty) return false;

    // 요청 실패 시 저장된 토큰을 유지하고 호출한 화면으로 오류를 전달합니다.
    final tokens = await _authService.refreshTokens(refreshToken);
    await tokenStorage.saveTokens(
      access: tokens.access,
      refresh: tokens.refresh,
    );
    _apiClient.setAccessToken(tokens.access);
    return true;
  }

  Future<AuthLoginResult> loginWithKakao(String idToken) async {
    _apiClient.clearAccessToken();
    await tokenStorage.clearTokens();
    final deviceId = await tokenStorage.getDeviceId();
    final result = await _authService.loginWithKakao(
      idToken: idToken,
      deviceId: deviceId,
    );
    await tokenStorage.saveTokens(
      access: result.tokens.access,
      refresh: result.tokens.refresh,
    );
    _apiClient.setAccessToken(result.tokens.access);
    return result;
  }

  Future<void> loginForDevelopment({required bool linkedPatient}) async {
    // 이전 테스트 계정의 인증 정보 제거
    _apiClient.clearAccessToken();
    await tokenStorage.deleteRefreshToken();

    // 선택한 테스트 계정으로 로그인
    final tokens = await _authService.loginForDevelopment(
      linkedPatient: linkedPatient,
    );

    // 저장 성공 후 인증이 필요한 API 요청 준비
    await tokenStorage.saveTokens(
      access: tokens.access,
      refresh: tokens.refresh,
    );
    _apiClient.setAccessToken(tokens.access);
  }
}
