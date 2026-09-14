import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/core/storage/token_storage.dart';
import 'package:flutter_patient/features/auth/repository/auth_repository.dart';
import 'package:flutter_patient/features/auth/view/dev_login_screen.dart';
import 'kakao_login_test.dart' show LoginAdapter;
import 'package:flutter_patient/features/auth/service/google_login_service.dart';

class GoogleMemoryStorage extends TokenStorage {
  String? access, refresh;
  bool failSave = false;
  @override
  Future<String> getDeviceId() async => 'test-device';
  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    this.access = access;
    if (failSave) throw StateError('storage failed');
    this.refresh = refresh;
  }
}

void main() {
  test('SDK 진단은 상세 원인을 남기고 이메일과 토큰을 가린다', () {
    final message = googleLoginDiagnostic(const GoogleSignInException(
      code: GoogleSignInExceptionCode.unknownError,
      description: 'Reauthentication failed user@example.com Bearer secret-token',
    ));
    expect(message, contains('Reauthentication failed'));
    expect(message, isNot(contains('user@example.com')));
    expect(message, isNot(contains('secret-token')));
  });
  late ApiClient client;
  late LoginAdapter adapter;
  late GoogleMemoryStorage storage;
  late AuthRepository repository;
  setUp(() {
    client = ApiClient();
    adapter = LoginAdapter();
    client.dio.httpClientAdapter = adapter;
    storage = GoogleMemoryStorage();
    repository = AuthRepository(apiClient: client, tokenStorage: storage);
  });
  tearDown(() => client.dispose());
  test('구글 ID 토큰을 전송하고 자체 토큰만 저장한다', () async {
    client.setAccessToken('old');
    await repository.loginWithGoogle('fake-google-token');
    expect(adapter.request!.path, '/api/auth/social/login/');
    expect(adapter.request!.data, {
      'identity_type': 'GOOGLE',
      'id_token': 'fake-google-token',
      'device_id': 'test-device',
      'device_name': 'Android Device',
      'platform': 'ANDROID',
    });
    expect(adapter.request!.headers.containsKey('Authorization'), isFalse);
    expect(storage.access, 'server-access');
    expect(storage.refresh, 'server-refresh');
    expect(client.dio.options.headers['Authorization'], 'Bearer server-access');
  });
  test('저장 실패 시 부분 저장 토큰과 인증 헤더를 남기지 않는다', () async {
    storage.failSave = true;
    await expectLater(repository.loginWithGoogle('fake'), throwsStateError);
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
    expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
  });
  test('서버 거절 시 세션을 만들지 않는다', () async {
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) => h.reject(
          DioException(
            requestOptions: o,
            response: Response(requestOptions: o, statusCode: 401),
          ),
        ),
      ),
    );
    await expectLater(
      repository.loginWithGoogle('fake'),
      throwsA(isA<DioException>()),
    );
    expect(storage.access, isNull);
  });
  testWidgets('버튼에서 서버 로그인 성공 후 기존 인증 완료 흐름을 호출한다', (tester) async {
    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DevLoginScreen(
          repository: repository,
          googleAuthenticate: () async => 'fake',
          onAuthenticated: () async {
            completed = true;
          },
        ),
      ),
    );
    await tester.tap(find.text('구글 로그인/회원가입'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(storage.access, 'server-access');
  });
  testWidgets('계정 선택 취소는 서버 로그인으로 이어지지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DevLoginScreen(
          repository: repository,
          googleAuthenticate: () async {
            throw const GoogleSignInException(
              code: GoogleSignInExceptionCode.canceled,
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('구글 로그인/회원가입'));
    await tester.pumpAndSettle();
    expect(find.text('구글 로그인을 취소했어요.'), findsOneWidget);
    expect(adapter.request, isNull);
  });
}
