import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/reservation/repository/reservation_repository.dart';
import 'package:flutter_patient/features/reservation/view/questionnaire_screen.dart';

class QuestionnaireAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool empty = false;
  String? status;
  List<Map<String, dynamic>>? customQuestions;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object data;
    if (options.method == 'GET') {
      data = empty
          ? []
          : [
              {
                'template': {
                  'id': 1,
                  'name': '기본 문진표',
                  'questions': [
                    {
                      'id': 1,
                      'question_text': '증상',
                      'question_type': 'TEXT',
                      'is_required': true,
                      'display_order': 1,
                      'options_json': null,
                    },
                    {
                      'id': 2,
                      'question_text': '복약 여부',
                      'question_type': 'BOOLEAN',
                      'is_required': true,
                      'display_order': 2,
                      'options_json': null,
                    },
                  ],
                },
                'response_status': status,
                'response_id': status == null ? null : 10,
              },
            ];
    } else {
      data = {'status': options.method == 'PUT' ? 'DRAFT' : 'SUBMITTED'};
    }
    if (options.method == 'GET' && !empty && customQuestions != null) {
      ((data as List).first['template'] as Map)['questions'] = customQuestions;
    }
    return ResponseBody.fromString(
      jsonEncode(data),
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
  late QuestionnaireAdapter adapter;
  setUp(() {
    client = ApiClient();
    adapter = QuestionnaireAdapter();
    client.dio.httpClientAdapter = adapter;
  });
  tearDown(() => client.dispose());

  testWidgets('단계 저장은 없음 선택으로 숨긴 답변을 제외하고 앞 단계 답변을 유지한다', (tester) async {
    adapter.customQuestions = [
      {'id': 1, 'question_code': 'SYMPTOM', 'question_text': '증상 선택', 'question_type': 'MULTI', 'is_required': true, 'step': 1, 'display_order': 1,
       'options_json': [{'value': 'PAIN', 'label': '통증'}, {'value': 'NONE', 'label': '없음'}], 'ui_config_json': {'exclusive_values': ['NONE']}},
      {'id': 2, 'question_code': 'DETAIL', 'question_text': '통증 설명', 'question_type': 'TEXT', 'is_required': true, 'step': 1, 'display_order': 2,
       'condition_json': {'question_code': 'SYMPTOM', 'operator': 'contains', 'value': 'PAIN'}},
      {'id': 3, 'question_code': 'NOTE', 'question_text': '추가 메모', 'question_type': 'TEXT', 'is_required': false, 'step': 2, 'display_order': 3},
    ];
    await tester.pumpWidget(MaterialApp(home: QuestionnaireScreen(reservationId: 8, repository: ReservationRepository(client))));
    await tester.pumpAndSettle();
    expect(find.text('통증 설명 (필수)'), findsNothing);
    await tester.tap(find.text('통증'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '이 답변은 지워져야 함');
    await tester.tap(find.text('없음'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2단계'), findsOneWidget);
    expect(adapter.requests.last.data['answers'], [{'question_id': 1, 'value': ['NONE']}]);
    await tester.enterText(find.byType(TextFormField), '유지할 메모');
    await tester.ensureVisible(find.text('이전'));
    await tester.tap(find.text('이전'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('유지할 메모'), findsOneWidget);
    expect(adapter.requests.last.data['answers'], [
      {'question_id': 1, 'value': ['NONE']}, {'question_id': 3, 'value': '유지할 메모'},
    ]);
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuestionnaireScreen(
          reservationId: 8,
          repository: ReservationRepository(client),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('문진표가 없으면 예약 문진 미등록 안내를 표시한다', (tester) async {
    adapter.empty = true;
    await open(tester);
    expect(find.textContaining('등록된 문진표가 없어요'), findsOneWidget);
    expect(
      adapter.requests.single.path,
      '/api/patient/reservations/8/questionnaires/',
    );
  });
  testWidgets('기존 임시 저장 답변은 빈 답변으로 덮어쓰지 않는다', (tester) async {
    adapter.status = 'DRAFT';
    await open(tester);
    expect(find.textContaining('기존 답변을 보호'), findsOneWidget);
    expect(find.text('임시 저장'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(adapter.requests.length, 1);
  });
  testWidgets('필수 답변 확인 후 false를 포함한 전체 답변 저장 뒤 제출한다', (tester) async {
    await open(tester);
    await tester.ensureVisible(find.text('최종 제출'));
    await tester.tap(find.text('최종 제출'));
    await tester.pumpAndSettle();
    expect(find.text('필수 질문에 모두 답해 주세요.'), findsOneWidget);
    expect(adapter.requests.length, 1);
    await tester.enterText(find.byType(TextFormField), '증상 기록');
    await tester.tap(find.text('아니요'));
    await tester.ensureVisible(find.text('최종 제출'));
    await tester.tap(find.text('최종 제출'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제출'));
    await tester.pumpAndSettle();
    expect(adapter.requests.map((r) => r.method), ['GET', 'PUT', 'POST']);
    expect(adapter.requests[1].data, {
      'template_id': 1,
      'answers': [
        {'question_id': 1, 'value': '증상 기록'},
        {'question_id': 2, 'value': false},
      ],
    });
    expect(
      adapter.requests.last.path,
      '/api/patient/reservations/8/questionnaire-responses/submit/',
    );
    expect(adapter.requests.last.data, {'template_id': 1});
    expect(find.text('제출 완료'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '최종 제출'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('증상 기록'), findsOneWidget);
    expect(find.text('아니요'), findsOneWidget);
  });
}
