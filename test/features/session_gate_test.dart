import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/core/storage/token_storage.dart';
import 'package:flutter_patient/features/auth/repository/auth_repository.dart';
import 'package:flutter_patient/features/auth/view/session_gate.dart';
import 'package:flutter_patient/features/home/view/dashboard_screen.dart';

class GateRepository extends AuthRepository {
  GateRepository(ApiClient client)
    : super(apiClient: client, tokenStorage: TokenStorage());
  bool restored = true;
  bool linked = false;
  bool cleared = false;
  int restores = 0;
  int checks = 0;
  DioException? restoreError;
  DioException? linkError;

  @override
  Future<bool> restoreSession() async {
    restores++;
    if (restoreError != null) throw restoreError!;
    return restored;
  }

  @override
  Future<bool> hasPatientLink() async {
    checks++;
    if (linkError != null) throw linkError!;
    return linked;
  }

  @override
  Future<void> clearSession() async => cleared = true;
}

void main() {
  late ApiClient client;
  late GateRepository repository;
  setUp(() {
    client = ApiClient();
    repository = GateRepository(client);
  });
  tearDown(() => client.dispose());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SessionGate(repository: repository)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('저장된 세션이 없으면 로그인 화면으로 이동한다', (tester) async {
    repository.restored = false;
    await open(tester);
    expect(find.text('카카오 로그인/회원가입'), findsOneWidget);
    expect(repository.checks, 0);
  });

  testWidgets('미연결 안내에서 연결 상태를 다시 확인해 대시보드로 이동한다', (tester) async {
    await open(tester);
    expect(find.text('아직 연결된 병원기록이 없어요'), findsOneWidget);
    repository.linked = true;
    await tester.tap(find.text('연결 상태 다시 확인'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(repository.restores, 1);
  });

  testWidgets('연결 조회 실패는 세션을 유지하고 토큰을 다시 갱신하지 않고 재시도한다', (tester) async {
    repository.linkError = DioException(
      requestOptions: RequestOptions(path: '/link-status/'),
      type: DioExceptionType.connectionError,
    );
    await open(tester);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(repository.cleared, isFalse);
    repository.linkError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('아직 연결된 병원기록이 없어요'), findsOneWidget);
    expect(repository.restores, 1);
  });

  testWidgets('갱신 API가 401을 반환하면 세션을 지우고 로그인 화면을 표시한다', (tester) async {
    final request = RequestOptions(path: '/api/auth/refresh/');
    repository.restoreError = DioException(
      requestOptions: request,
      response: Response(requestOptions: request, statusCode: 401),
      type: DioExceptionType.badResponse,
    );
    await open(tester);
    expect(repository.cleared, isTrue);
    expect(find.text('카카오 로그인/회원가입'), findsOneWidget);
  });
}
