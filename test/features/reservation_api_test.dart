import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/reservation/model/patient_reservation.dart';
import 'package:flutter_patient/features/reservation/repository/reservation_repository.dart';
import 'package:flutter_patient/features/reservation/view/reservation_list_screen.dart';

Map<String, dynamic> reservationJson({String status = 'REQUESTED'}) => {
  'id': 12,
  'reserved_at': '2099-09-15T01:30:00Z',
  'status': status,
  'applicant_name': '테스트환자',
  'patient': null,
  'doctor': 3,
  'department': 2,
  'cancel_reason': null,
};

class ReservationAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool canceled = false;
  bool empty = false;
  bool failCancel = false;
  bool failList = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final cancel = options.path.endsWith('/cancel/');
    final list = options.path == ReservationRepository.path;
    if ((cancel && failCancel) || (list && failList)) {
      return ResponseBody.fromString(
        '{}',
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (cancel) canceled = true;
    final data = reservationJson(status: canceled ? 'CANCELED' : 'REQUESTED');
    return ResponseBody.fromString(
      jsonEncode(list ? (empty ? [] : [data]) : data),
      200,
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
  late ReservationAdapter adapter;
  late ReservationRepository repository;
  setUp(() {
    client = ApiClient();
    client.setAccessToken('fake-patient-access');
    adapter = ReservationAdapter();
    client.dio.httpClientAdapter = adapter;
    repository = ReservationRepository(client);
  });
  tearDown(() => client.dispose());

  test('한국 시간 표시와 취소·지난 일정 분류, 상태 의미를 보존한다', () {
    final item = PatientReservation.fromJson(reservationJson());
    expect(item.dateLabel, '2099.09.15 · 10:30');
    expect(item.statusLabel, '승인 대기');
    expect(item.isPast(DateTime.utc(2099, 9, 14)), isFalse);
    expect(item.isPast(DateTime.utc(2099, 9, 16)), isTrue);
    final canceled = PatientReservation.fromJson(
      reservationJson(status: 'CANCELED'),
    );
    expect(canceled.isPast(DateTime.utc(2099, 9, 14)), isTrue);
    expect(canceled.canCancel(DateTime.utc(2099, 9, 14)), isFalse);
    expect(
      PatientReservation.fromJson(
        reservationJson(status: 'ACCEPTED'),
      ).statusLabel,
      '예약 승인',
    );
  });

  test('배열 응답을 읽고 동일한 환자 인증 헤더를 사용한다', () async {
    final items = await repository.getReservations();
    expect(items.single.id, 12);
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer fake-patient-access',
    );
    expect(adapter.requests.single.queryParameters, isEmpty);
    adapter.empty = true;
    expect(await repository.getReservations(), isEmpty);
  });

  testWidgets('실제 목록 상세 취소 확인 후 목록을 새로고침한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ReservationListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('승인 대기'), findsOneWidget);
    await tester.tap(find.text('예약 상세 보기'));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.map((request) => request.path),
      containsAll([
        '/api/patient/reservations/12/',
        '/api/patient/doctors/3/',
        '/api/patient/departments/',
      ]),
    );
    await tester.ensureVisible(find.text('예약 취소'));
    await tester.tap(find.text('예약 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('유지하기'));
    await tester.pumpAndSettle();
    expect(adapter.canceled, isFalse);
    await tester.tap(find.text('예약 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('예약 취소하기'));
    await tester.pumpAndSettle();
    expect(adapter.canceled, isTrue);
    expect(adapter.requests.last.method, 'POST');
    expect(adapter.requests.last.data, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('예정된 예약이 없어요.'), findsOneWidget);
    await tester.tap(find.text('지난 예약'));
    await tester.pumpAndSettle();
    expect(find.text('예약 취소'), findsOneWidget);
  });

  testWidgets('목록 오류를 빈 목록으로 표시하지 않고 재시도한다', (tester) async {
    adapter.failList = true;
    await tester.pumpWidget(
      MaterialApp(home: ReservationListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('예정된 예약이 없어요.'), findsNothing);
    adapter.failList = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('승인 대기'), findsOneWidget);
  });

  testWidgets('취소 실패 시 예약 상태를 유지한다', (tester) async {
    adapter.failCancel = true;
    await tester.pumpWidget(
      MaterialApp(home: ReservationListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('예약 상세 보기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('예약 취소'));
    await tester.tap(find.text('예약 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('예약 취소하기'));
    await tester.pumpAndSettle();
    expect(adapter.canceled, isFalse);
    expect(find.text('승인 대기'), findsOneWidget);
    expect(find.textContaining('취소 반영 여부'), findsOneWidget);
  });
}
