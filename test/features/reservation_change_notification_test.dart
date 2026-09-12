import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/notification/repository/notification_repository.dart';
import 'package:flutter_patient/features/notification/view/notification_screen.dart';
import 'package:flutter_patient/features/reservation/repository/reservation_repository.dart';

Map<String, dynamic> notice({bool read = false, int id = 31}) => {
  'id': id,
  'is_read': read,
  'notification': {
    'id': 18,
    'title': '검사 결과 공개',
    'body': '결과가 공개됐어요.',
    'notification_type': 'RESULT_RELEASED',
    'reference_type': 'RESULT_RELEASE',
    'reference_id': 55,
    'created_at': '2026-09-12T15:00:00+09:00',
  },
};

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool failRead = false;
  bool empty = false;
  bool reservationNotice = false;
  Map<String, dynamic> notificationData({bool read = false}) {
    final data = notice(read: read);
    if (reservationNotice) {
      data['notification'] = <String, dynamic>{
        ...data['notification'] as Map<String, dynamic>,
        'title': '예약 변경이 승인되었습니다.',
        'notification_type': 'RESERVATION_CHANGE_APPROVED',
        'reference_type': 'RESERVATION',
        'reference_id': 8,
      };
    }
    return data;
  }
  int code = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    Object data;
    int status = code;
    if (path.endsWith('/change-requests/')) {
      status = 201;
      data = {
        'id': 15,
        'reservation': 42,
        'status': 'PENDING',
        'requested_reserved_at': options.data['requested_reserved_at'],
      };
    } else if (path.endsWith('/read-all/')) {
      data = {'updated_count': 3};
    } else if (path.endsWith('/read/')) {
      data = notificationData(read: true);
      if (failRead) status = 500;
    } else if (path.endsWith('/unread-count/')) {
      data = {'unread_count': 2};
    } else if (path == '/api/patient/reservations/8/') {
      data = {
        'id': 8,
        'reserved_at': '2099-09-14T09:30:00+09:00',
        'status': 'ACCEPTED',
        'applicant_name': '테스트환자',
        'doctor': 3,
        'department': 1,
      };
    } else if (path == '/api/patient/doctors/3/') {
      data = {'id': 3, 'name': '김도윤'};
    } else if (path == '/api/patient/departments/') {
      data = [{'id': 1, 'name': '순환기내과'}];
    } else {
      data = {
        'page': options.queryParameters['page'] ?? 1,
        'has_next': false,
        'results': empty ? [] : [notificationData()],
      };
    }
    return ResponseBody.fromString(
      jsonEncode(data),
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
  late Adapter adapter;
  late NotificationRepository notifications;
  late ReservationRepository reservations;
  setUp(() {
    client = ApiClient()..setAccessToken('fake-access');
    adapter = Adapter();
    client.dio.httpClientAdapter = adapter;
    notifications = NotificationRepository(client);
    reservations = ReservationRepository(client);
  });
  tearDown(() => client.dispose());

  testWidgets('예약 알림은 recipient 31을 읽고 예약 8의 최신 시간을 조회한다', (tester) async {
    adapter.reservationNotice = true;
    await tester.pumpWidget(MaterialApp(
      home: NotificationScreen(reservationRepository: reservations),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('예약 변경이 승인되었습니다.'));
    await tester.pumpAndSettle();
    final paths = adapter.requests.map((r) => r.path).toList();
    expect(paths, contains('/api/patient/notifications/31/read/'));
    expect(paths, isNot(contains('/api/patient/notifications/18/read/')));
    expect(paths, contains('/api/patient/reservations/8/'));
    expect(find.text('예약 상세'), findsOneWidget);
    expect(find.text('2099.09.14 · 09:30'), findsOneWidget);
    expect(find.text('예약 승인'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  test('예약 변경은 새 시각과 사유만 보내고 승인 대기 결과를 읽는다', () async {
    final when = DateTime.utc(2099, 9, 20, 1, 30);
    final result = await reservations.requestReservationChange(
      reservationId: 42,
      requestedAt: when,
      reason: '개인 일정',
    );
    expect(result.status, 'PENDING');
    expect(result.reservationId, 42);
    expect(
      adapter.requests.single.path,
      '/api/patient/reservations/42/change-requests/',
    );
    expect(adapter.requests.single.data, {
      'requested_reserved_at': when.toIso8601String(),
      'reason': '개인 일정',
    });
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer fake-access',
    );
  });
  test('과거 시간 변경 요청은 서버로 보내지 않는다', () async {
    await expectLater(
      reservations.requestReservationChange(
        reservationId: 42,
        requestedAt: DateTime.utc(2000),
      ),
      throwsArgumentError,
    );
    expect(adapter.requests, isEmpty);
  });
  test('알림은 외부 recipient ID로 읽음 처리한다', () async {
    final page = await notifications.list(page: 2, unreadOnly: true);
    expect(adapter.requests.last.queryParameters, {'page': 2, 'read': false});
    expect(page.items.single.recipientId, 31);
    final read = await notifications.markRead(page.items.single.recipientId);
    expect(adapter.requests.last.path, '/api/patient/notifications/31/read/');
    expect(read.isRead, isTrue);
    expect(read.dateLabel, '2026.09.12 15:00');
  });
  test('전체 읽음과 미읽음 개수는 각각의 API를 사용한다', () async {
    await notifications.readAll();
    expect(adapter.requests.last.path, '/api/patient/notifications/read-all/');
    expect(await notifications.unreadCount(), 2);
  });
  testWidgets('알림 탭은 서버 읽음 성공 후 내용을 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(reservationRepository: reservations),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('검사 결과 공개'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(adapter.requests.last.path, '/api/patient/notifications/31/read/');
    expect(find.text('관련 결과 화면 연결은 준비 중이에요.'), findsOneWidget);
  });
  testWidgets('읽음 실패 시 읽지 않은 상태를 유지하고 안내한다', (tester) async {
    adapter.failRead = true;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(reservationRepository: reservations),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('검사 결과 공개'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('읽음 처리를 완료하지 못했어요'), findsOneWidget);
  });
  testWidgets('알림 조회 실패는 빈 알림과 구분한다', (tester) async {
    adapter.code = 401;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(reservationRepository: reservations),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('알림이 없어요.'), findsNothing);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
