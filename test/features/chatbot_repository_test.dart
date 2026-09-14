import 'package:flutter_patient/features/chatbot/model/chatbot_conversation.dart';
import 'package:flutter_patient/features/chatbot/model/chatbot_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('챗봇 대화 목록 응답을 파싱한다', () {
    final page = ChatbotConversationPage.fromJson({
      'page': 1,
      'page_size': 20,
      'total': 1,
      'has_next': false,
      'results': [
        {
          'id': 11,
          'title': '검사 결과 질문',
          'status': 'ACTIVE',
          'started_at': '2026-09-14T01:00:00Z',
          'ended_at': null,
        },
      ],
    });

    expect(page.total, 1);
    expect(page.results.single.id, 11);
    expect(page.results.single.displayTitle, '검사 결과 질문');
    expect(page.results.single.isActive, isTrue);
  });

  test('Backend ASSISTANT와 SAFE 값을 정상 계약으로 처리한다', () {
    final message = ChatbotMessage.fromJson({
      'id': 21,
      'conversation': 11,
      'sender_type': 'ASSISTANT',
      'message_text': '검사 결과를 설명해 드릴게요.',
      'message_type': 'TEXT',
      'safety_status': 'SAFE',
      'created_at': '2026-09-14T01:01:00Z',
    });

    expect(message.isChatbot, isTrue);
    expect(message.normalizedSenderType, 'CHATBOT');
    expect(message.normalizedSafetyStatus, 'PASS');
  });

  test('PENDING 상태는 최종 safety 결과로 사용하지 않는다', () {
    final message = ChatbotMessage.fromJson({
      'id': 22,
      'conversation': 11,
      'sender_type': 'PATIENT',
      'message_text': '이 결과가 무슨 뜻인가요?',
      'message_type': 'TEXT',
      'safety_status': 'PENDING',
      'created_at': '2026-09-14T01:02:00Z',
    });

    expect(message.isPatient, isTrue);
    expect(message.normalizedSafetyStatus, isNull);
  });

  test('챗봇 서비스 미연결 202 응답을 파싱한다', () {
    final result = ChatbotSendResult.fromJson({
      'patient_message': {
        'id': 23,
        'conversation': 11,
        'sender_type': 'PATIENT',
        'message_text': '예약을 확인해 줘',
        'message_type': 'TEXT',
        'safety_status': 'PENDING',
        'created_at': '2026-09-14T01:03:00Z',
      },
      'assistant_message': null,
      'integration_status': 'NOT_CONFIGURED',
      'detail': 'CHATBOT_API_URL not configured',
    });

    expect(result.patientMessage.id, 23);
    expect(result.assistantMessage, isNull);
    expect(result.completed, isFalse);
    expect(result.integrationStatus, 'NOT_CONFIGURED');
  });
}
