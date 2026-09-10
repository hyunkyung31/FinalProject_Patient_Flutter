import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/core/storage/token_storage.dart';
import 'package:flutter_patient/features/auth/repository/auth_repository.dart';

import 'kakao_login_test.dart' show LoginAdapter;

class MemoryTokenStorage extends TokenStorage {
  String? refresh;
  String? access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    this.access = access;
    this.refresh = refresh;
  }
}

void main() {
  late ApiClient client;
  late LoginAdapter adapter;
  late MemoryTokenStorage storage;
  late AuthRepository repository;

  setUp(() {
    client = ApiClient();
    adapter = LoginAdapter();
    client.dio.httpClientAdapter = adapter;
    storage = MemoryTokenStorage();
    repository = AuthRepository(apiClient: client, tokenStorage: storage);
  });
  tearDown(() => client.dispose());

  test('저장된 토큰이 없으면 요청하지 않고 이전 인증 헤더를 제거한다', () async {
    client.setAccessToken('old-access');
    expect(await repository.restoreSession(), isFalse);
    expect(adapter.request, isNull);
    expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
  });

  test('갱신된 두 토큰을 저장하고 새 access를 요청에 적용한다', () async {
    storage.refresh = 'old-refresh';
    client.setAccessToken('old-access');
    expect(await repository.restoreSession(), isTrue);
    expect(adapter.request!.path, '/api/auth/refresh/');
    expect(adapter.request!.data, {'refresh': 'old-refresh'});
    expect(adapter.request!.headers.containsKey('Authorization'), isFalse);
    expect(storage.access, 'server-access');
    expect(storage.refresh, 'server-refresh');
    expect(client.dio.options.headers['Authorization'], 'Bearer server-access');
  });

  test('연결 실패 시 저장된 refresh를 유지하고 오류를 전달한다', () async {
    storage.refresh = 'old-refresh';
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      ),
    );
    await expectLater(
      repository.restoreSession(),
      throwsA(isA<DioException>()),
    );
    expect(storage.refresh, 'old-refresh');
    expect(storage.access, isNull);
    expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
  });
}
