import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/app.dart';
import 'package:flutter_patient/features/onboarding/repository/onboarding_repository.dart';
import 'package:flutter_patient/core/theme/app_preferences.dart';
import 'package:flutter_patient/features/patient_services/repository/patient_services_repository.dart';
import 'package:flutter_patient/features/patient_services/view/patient_services_screen.dart';
import 'package:flutter_patient/features/reservation/repository/reservation_repository.dart';

class IncompleteOnboarding extends OnboardingRepository {
  @override
  Future<bool> isCompleted() async => false;
}

class ServiceAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object? result = <String, dynamic>{};
  int status = 200;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(result), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('실제 앱의 다크 테마가 어두운 배경에 밝은 글씨를 적용한다', (tester) async {
    SharedPreferences.setMockInitialValues({'ui.dark':true});
    await AppPreferences.instance.ready;
    await AppPreferences.instance.save(dark:true);
    await tester.pumpWidget(MyApp(onboardingRepository: IncompleteOnboarding()));
    await tester.pump();
    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    expect(theme.brightness, Brightness.dark);
    expect(theme.textTheme.bodyMedium!.color!.computeLuminance(), greaterThan(0.5));
    await tester.pumpWidget(const SizedBox());
  });
  late ApiClient client;
  late ServiceAdapter adapter;
  late PatientServicesRepository repository;
  setUp(() {
    client = ApiClient()..setAccessToken('fake-access');
    adapter = ServiceAdapter();
    client.dio.httpClientAdapter = adapter;
    repository = PatientServicesRepository(client);
  });
  tearDown(() => client.dispose());

  test('환자정보 조회에 기존 환자 인증 헤더를 사용한다', () async {
    adapter.result = {'name':'테스트환자','contact':'01012345678'};
    expect((await repository.profile())['name'], '테스트환자');
    expect(adapter.requests.single.path, '/api/patients/me/');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer fake-access');
  });
  test('정보 변경은 병원 원본 PATCH 대신 변경 요청을 생성한다', () async {
    await repository.requestChange('name','변경 이름','오타 정정');
    expect(adapter.requests.single.method,'POST');
    expect(adapter.requests.single.path,'/api/patients/me/information-change-requests/');
    expect(adapter.requests.single.data, {'field_name':'name','requested_value':'변경 이름','reason':'오타 정정'});
  });
  test('연결 요청은 서버 인증 기록 ID만 전달한다', () async {
    await repository.requestLink(12);
    expect(adapter.requests.single.path,'/api/record-link-request/');
    expect(adapter.requests.single.data,{'verification_id':12});
  });
  test('동의 문서 페이지와 다음 페이지 여부를 파싱한다', () async {
    adapter.result = {'results':[{'id':7,'title':'동의 문서'}],'next':'https://example.invalid/?page=3'};
    final page = await repository.documents(2);
    expect(page.hasNext,isTrue);
    expect(page.items.single['id'],7);
    expect(adapter.requests.single.queryParameters,{'page':2});
  });
  test('동의와 철회가 명세의 ID 및 사유를 전달한다', () async {
    await repository.consent(7);
    expect(adapter.requests.last.data,{'consent_document_id':7,'consented':true});
    await repository.withdraw(11,'선택 동의 철회');
    expect(adapter.requests.last.path,'/api/consents/11/withdraw/');
    expect(adapter.requests.last.data,{'reason':'선택 동의 철회'});
  });
  test('인증 실패를 빈 목록으로 감추지 않는다', () async {
    adapter.status = 401;
    await expectLater(repository.consents(1),throwsA(isA<DioException>()));
  });
  testWidgets('환자정보 화면은 서버 값을 표시한다', (tester) async {
    adapter.result = {'name':'테스트환자','birth_date':'1995-04-20','gender':'FEMALE','contact':'01012345678','medical_record_no':'TEST-001'};
    await tester.pumpWidget(MaterialApp(home: PatientServicesScreen(repository:ReservationRepository(client),section:'profile')));
    await tester.pumpAndSettle();
    expect(find.text('테스트환자'),findsOneWidget);
    expect(find.text('정보 변경 요청'),findsOneWidget);
  });
  test('화면 설정은 저장 후 다시 불러올 수 있다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPreferences();
    await prefs.ready;
    await prefs.save(dark:true,textScale:1.2);
    final restored = AppPreferences();
    await restored.ready;
    expect(restored.dark,isTrue);
    expect(restored.textScale,1.2);
    prefs.dispose(); restored.dispose();
  });
}
