import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _sessionKey = 'auth_session_v1';
  static const String _deviceKey = 'auth_device_id';

  Future<String> getDeviceId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = base64UrlEncode(List.generate(24, (_) => random.nextInt(256)));
    await _storage.write(key: _deviceKey, value: id);
    return id;
  }

  // 두 토큰을 한 항목에 저장해 서로 다른 세션의 토큰이 섞이지 않게 합니다.
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    if (access.trim().isEmpty || refresh.trim().isEmpty) {
      throw ArgumentError('빈 토큰은 저장할 수 없습니다.');
    }
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode({'access': access, 'refresh': refresh}),
    );
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // 리프레시 토큰 저장
  Future<void> saveRefreshToken(String token) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('빈 리프레시 토큰은 저장할 수 없습니다.');
    }

    await _storage.write(key: _refreshTokenKey, value: token);
  }

  // 저장된 리프레시 토큰 조회
  Future<String?> readRefreshToken() async {
    final session = await _storage.read(key: _sessionKey);
    if (session != null) {
      return (jsonDecode(session) as Map<String, dynamic>)['refresh'] as String;
    }
    return _storage.read(key: _refreshTokenKey);
  }

  // 로그아웃 시 리프레시 토큰 삭제
  Future<void> deleteRefreshToken() {
    return clearTokens();
  }
}
