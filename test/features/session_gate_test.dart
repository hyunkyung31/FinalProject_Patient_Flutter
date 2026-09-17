import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/core/storage/token_storage.dart';
import 'package:flutter_patient/features/auth/repository/auth_repository.dart';
import 'package:flutter_patient/features/auth/service/biometric_auth_service.dart';
import 'package:flutter_patient/features/auth/view/session_gate.dart';
import 'package:flutter_patient/features/home/view/dashboard_screen.dart';
import 'package:flutter_patient/features/patient_services/repository/patient_services_repository.dart';

class GateConsentRepository extends PatientServicesRepository {
  GateConsentRepository(super.client);
  List<Map<String, dynamic>> requiredDocumentsRows = [];
  int saved = 0;

  @override
  Future<List<Map<String, dynamic>>> requiredConsentDocuments() async =>
      requiredDocumentsRows;

  @override
  Future<void> consent(int documentId) async {
    saved++;
    requiredDocumentsRows = requiredDocumentsRows
        .where((document) => document['id'] != documentId)
        .toList();
  }
}

class GateRepository extends AuthRepository {
  GateRepository(ApiClient client)
    : super(apiClient: client, tokenStorage: TokenStorage());
  bool restored = true;
  bool linked = false;
  bool biometricRequired = false;
  bool biometricEnabled = false;
  bool cleared = false;
  int restores = 0;
  int checks = 0;
  DioException? restoreError;
  DioException? linkError;
  bool logoutFails = false;
  int logouts = 0;

  @override
  Future<void> logout() async {
    logouts++;
    if (logoutFails) throw StateError('test logout failure');
    cleared = true;
    restored = false;
  }

  @override
  Future<bool> restoreSession() async {
    restores++;
    if (restoreError != null) throw restoreError!;
    return restored;
  }

  @override
  Future<bool> requiresBiometricLogin() async => biometricRequired;

  @override
  Future<void> setBiometricLoginEnabled(bool enabled) async {
    biometricEnabled = enabled;
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

class GateBiometricAuthenticator implements BiometricAuthenticator {
  bool available = true;
  bool authenticated = true;
  int requests = 0;

  @override
  Future<bool> authenticate() async {
    requests++;
    return authenticated;
  }

  @override
  Future<bool> isAvailable() async => available;
}

void main() {
  late ApiClient client;
  late GateRepository repository;
  late GateBiometricAuthenticator biometricAuthenticator;
  late GateConsentRepository consentRepository;

  setUp(() {
    client = ApiClient();
    repository = GateRepository(client);
    biometricAuthenticator = GateBiometricAuthenticator();
    consentRepository = GateConsentRepository(client);
  });
  tearDown(() => client.dispose());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionGate(
          repository: repository,
          biometricAuthenticator: biometricAuthenticator,
          consentRepository: consentRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('필수 동의가 없으면 대시보드보다 동의 화면을 먼저 표시한다', (tester) async {
    consentRepository.requiredDocumentsRows = [
      {
        'id': 7,
        'title': '개인정보 처리 동의',
        'version': '1.0',
        'content_text': '예약과 진료 안내를 위해 개인정보를 처리합니다.',
      },
    ];
    await open(tester);
    expect(find.text('필수 약관 동의'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('필수 약관에 동의하고 시작하기'));
    await tester.pumpAndSettle();
    expect(consentRepository.saved, 1);

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('로그아웃 확인 후 로그인 화면으로 이동하고 재시작해도 유지된다', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(repository.logouts, 0);
    await tester.tap(find.byTooltip('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '로그아웃'));
    await tester.pumpAndSettle();
    expect(repository.cleared, isTrue);
    expect(find.text('카카오 로그인/회원가입'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await open(tester);
    expect(find.text('카카오 로그인/회원가입'), findsOneWidget);
  });

  testWidgets('로그아웃 실패의 재시도는 세션 복원이 아닌 로그아웃을 호출한다', (tester) async {
    repository.logoutFails = true;
    await open(tester);
    await tester.tap(find.byTooltip('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '로그아웃'));
    await tester.pumpAndSettle();
    expect(repository.cleared, isFalse);
    expect(find.text('카카오 로그인/회원가입'), findsNothing);
    repository.logoutFails = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(repository.logouts, 2);
    expect(repository.restores, 1);
    expect(find.text('카카오 로그인/회원가입'), findsOneWidget);
  });

  testWidgets('저장된 세션이 없으면 로그인 화면으로 이동한다', (tester) async {
    repository.restored = false;
    await open(tester);
    expect(find.text('카카오 로그인/회원가입'), findsOneWidget);
    expect(repository.checks, 0);
  });

  testWidgets('미연결 환자도 홈에 진입하고 연결 상태 갱신이 반영된다', (tester) async {
    await open(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(
      tester
          .widget<DashboardScreen>(find.byType(DashboardScreen))
          .patientLinked,
      isFalse,
    );
    expect(find.text('아직 연결된 병원기록이 없어요'), findsOneWidget);
    repository.linked = true;
    expect(find.text('연결 상태 다시 확인'), findsNothing);
    // 연결 화면 복귀 시 호출되는 갱신 콜백을 확인합니다.
    await tester
        .widget<DashboardScreen>(find.byType(DashboardScreen))
        .onRefreshLink!();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(
      tester
          .widget<DashboardScreen>(find.byType(DashboardScreen))
          .patientLinked,
      isTrue,
    );
    expect(find.text('김보미님,\n안녕하세요!'), findsNothing);
    expect(find.text('10월 20일 · 오전 10:30'), findsNothing);
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
  testWidgets('생체 로그인 활성 세션은 인증 성공 뒤에만 홈으로 이동한다', (tester) async {
    repository.biometricRequired = true;

    await open(tester);

    expect(find.text('생체 인증으로 로그인'), findsOneWidget);
    expect(repository.restores, 0);
    await tester.tap(find.text('생체 인증하기'));
    await tester.pumpAndSettle();

    expect(biometricAuthenticator.requests, 1);
    expect(repository.restores, 1);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
