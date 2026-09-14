import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/pharmacy/pharmacy_repository.dart';
import 'package:flutter_patient/features/pharmacy/pharmacy_screen.dart';
import 'package:flutter_patient/features/pharmacy/pharmacy_map.dart';

class PharmacyAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool fail = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    final row = {
      'id': 'p1',
      'name': '테스트약국',
      'address': '서울',
      'hours_available': true,
      'business_status': 'OPEN',
      'is_open_now': true,
    };
    return ResponseBody.fromString(
      jsonEncode(
        fail
            ? {'code': 'PHARMACY_PROVIDER_UNAVAILABLE'}
            : o.path.endsWith('/p1/')
            ? row
            : {
                'results': [row],
                'next': o.queryParameters['page'] == 1
                    ? 'https://untrusted.example/page'
                    : null,
              },
      ),
      fail ? 503 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('지도에는 유효 좌표와 식별자만 전달한다', () {
    final data =
        jsonDecode(
              pharmacyMapData(
                [
                  Pharmacy({
                    'id': 'p1',
                    'name': '약국',
                    'latitude': 37.5,
                    'longitude': 127.0,
                    'phone': 'private',
                  }),
                  Pharmacy({'id': 'p2', 'name': '좌표 없음'}),
                ],
                37.4,
                127.1,
              ),
            )
            as Map;
    expect((data['places'] as List).length, 1);
    expect(data['places'][0], {'id': 'p1', 'lat': 37.5, 'lng': 127.0});
    expect(data['location'], {'lat': 37.4, 'lng': 127.1});
  });
  late ApiClient client;
  late PharmacyAdapter adapter;
  late PharmacyRepository repository;
  setUp(() {
    client = ApiClient()..setAccessToken('fake');
    adapter = PharmacyAdapter();
    client.dio.httpClientAdapter = adapter;
    repository = PharmacyRepository(client);
  });
  tearDown(() => client.dispose());
  test('주변 조회는 환자 인증과 좌표를 전달한다', () async {
    await repository.search({
      'latitude': 37.5,
      'longitude': 127.0,
      'radius': 3000,
    });
    expect(adapter.requests.single.path, '/api/patient/pharmacies/nearby/');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer fake');
    expect(adapter.requests.single.queryParameters['size'], 15);
  });
  test('영업 상태는 시간 정보가 없거나 모순되면 미확인으로 표시한다', () {
    expect(
      Pharmacy({
        'id': 'x',
        'name': 'x',
        'is_open_now': true,
        'business_status': 'OPEN',
      }).status,
      '운영시간 정보 없음',
    );
  });
  testWidgets('지역 검색은 위치 요청 없이 조회하고 다음 페이지와 상세를 연다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PharmacyScreen(repository: repository)),
    );
    expect(adapter.requests, isEmpty);
    await tester.tap(find.text('약국명·지역 검색'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('약국명·지역 검색'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('약국명·지역 검색'));
    await tester.pumpAndSettle();
    expect(adapter.requests.single.path, '/api/patient/pharmacies/search/');
    await tester.scrollUntilVisible(
      find.text('테스트약국'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('등록 운영시간상 영업 중'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('더 보기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('더 보기'));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.last.uri.host,
      client.dio.options.baseUrl.isEmpty
          ? ''
          : Uri.parse(client.dio.options.baseUrl).host,
    );
    expect(adapter.requests.last.queryParameters['page'], 2);
    expect(find.text('테스트약국'), findsOneWidget);
    await tester.tap(find.text('테스트약국'));
    await tester.pumpAndSettle();
    expect(find.text('카카오맵 길찾기'), findsOneWidget);
    await tester.ensureVisible(find.text('상세 보기'));
    await tester.tap(find.text('상세 보기'));
    await tester.pumpAndSettle();
    expect(adapter.requests.last.path, '/api/patient/pharmacies/p1/');
    expect(find.text('약국 상세'), findsOneWidget);
  });
  testWidgets('제공기관 오류를 빈 결과로 표시하지 않는다', (tester) async {
    adapter.fail = true;
    await tester.pumpWidget(
      MaterialApp(home: PharmacyScreen(repository: repository)),
    );
    await tester.tap(find.text('약국명·지역 검색'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('약국명·지역 검색'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('약국명·지역 검색'));
    await tester.pumpAndSettle();
    expect(find.textContaining('제공기관에 연결할 수 없어요'), findsOneWidget);
    expect(find.textContaining('검색된 약국이 없어요'), findsNothing);
  });
}
