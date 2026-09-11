import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/core/storage/token_storage.dart';
import 'package:flutter_patient/features/auth/repository/auth_repository.dart';

class LogoutStorage extends TokenStorage {
  String? refresh = 'old-refresh';
  bool cleared = false;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    this.refresh = refresh;
  }

  @override
  Future<void> clearTokens() async {
    cleared = true;
    refresh = null;
  }
}

class LogoutAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool expired = false;
  bool offline = false;
  bool invalidRefresh = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final refresh = options.path == '/api/auth/refresh/';
    final status =
        (refresh && invalidRefresh) ||
            (!refresh &&
                expired &&
                options.headers['Authorization'] != 'Bearer new-access')
        ? 401
        : 200;
    return ResponseBody.fromString(
      refresh ? '{"access":"new-access","refresh":"new-refresh"}' : '{}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ApiClient client;
  late LogoutStorage storage;
  late LogoutAdapter adapter;
  late AuthRepository repository;
  setUp(() {
    client = ApiClient()..setAccessToken('old-access');
    storage = LogoutStorage();
    adapter = LogoutAdapter();
    client.dio.httpClientAdapter = adapter;
    repository = AuthRepository(apiClient: client, tokenStorage: storage);
  });
  tearDown(() => client.dispose());

  test('인증 헤더로 현재 세션 종료 후 저장된 토큰을 삭제한다', () async {
    await repository.logout();
    expect(adapter.requests.single.path, '/api/auth/logout/');
    expect(adapter.requests.single.method, 'POST');
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer old-access',
    );
    expect(storage.cleared, isTrue);
    expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
    expect(await repository.restoreSession(), isFalse);
  });
  test('연결 실패 시 재시도에 필요한 토큰을 유지한다', () async {
    adapter.offline = true;
    await expectLater(repository.logout(), throwsA(isA<DioException>()));
    expect(storage.cleared, isFalse);
    expect(storage.refresh, 'old-refresh');
  });
  test('만료된 access를 갱신하고 새 토큰으로 로그아웃한다', () async {
    adapter.expired = true;
    await repository.logout();
    expect(adapter.requests.map((r) => r.path).toList(), [
      '/api/auth/logout/',
      '/api/auth/refresh/',
      '/api/auth/logout/',
    ]);
    expect(adapter.requests.last.headers['Authorization'], 'Bearer new-access');
    expect(storage.cleared, isTrue);
  });
  test('refresh도 401이면 로컬 세션을 삭제한다', () async {
    adapter.expired = true;
    adapter.invalidRefresh = true;
    await repository.logout();
    expect(storage.cleared, isTrue);
    expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
  });
}
