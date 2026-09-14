import 'package:flutter/material.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/chatbot/model/chatbot_conversation.dart';
import 'package:flutter_patient/features/chatbot/model/chatbot_message.dart';
import 'package:flutter_patient/features/chatbot/repository/chatbot_repository.dart';
import 'package:flutter_patient/features/chatbot/view/chatbot_conversation_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeChatbotRepository extends ChatbotRepository {
  FakeChatbotRepository() : super(ApiClient());

  final conversation = ChatbotConversation(
    id: 10,
    title: '검사 결과 질문',
    status: 'ACTIVE',
    startedAt: DateTime.utc(2026, 9, 14),
  );

  int sentCount = 0;

  @override
  Future<ChatbotConversationPage> getConversations({
    String? status,
    int page = 1,
  }) async {
    return ChatbotConversationPage(
      page: 1,
      pageSize: 20,
      total: 1,
      hasNext: false,
      results: [conversation],
    );
  }

  @override
  Future<ChatbotConversation> createConversation({String? title}) async {
    return conversation;
  }

  @override
  Future<ChatbotConversationDetail> getConversation(int conversationId) async {
    return ChatbotConversationDetail(
      conversation: conversation,
      messages: [
        ChatbotMessage(
          id: 1,
          conversationId: conversation.id,
          senderType: 'PATIENT',
          messageText: '검사 결과를 설명해 주세요.',
          messageType: 'TEXT',
          safetyStatus: 'PASS',
          createdAt: DateTime.utc(2026, 9, 14, 1),
        ),
        ChatbotMessage(
          id: 2,
          conversationId: conversation.id,
          senderType: 'CHATBOT',
          messageText: '확인된 결과를 기준으로 설명해 드릴게요.',
          messageType: 'TEXT',
          safetyStatus: 'PASS',
          createdAt: DateTime.utc(2026, 9, 14, 1, 1),
        ),
      ],
    );
  }

  @override
  Future<ChatbotSendResult> sendMessage({
    required int conversationId,
    required String messageText,
  }) async {
    sentCount += 1;

    return ChatbotSendResult(
      patientMessage: ChatbotMessage(
        id: 3,
        conversationId: conversationId,
        senderType: 'PATIENT',
        messageText: messageText,
        messageType: 'TEXT',
        safetyStatus: null,
        createdAt: DateTime.utc(2026, 9, 14, 1, 2),
      ),
      assistantMessage: ChatbotMessage(
        id: 4,
        conversationId: conversationId,
        senderType: 'CHATBOT',
        messageText: '답변입니다.',
        messageType: 'TEXT',
        safetyStatus: 'PASS',
        createdAt: DateTime.utc(2026, 9, 14, 1, 3),
      ),
      integrationStatus: 'COMPLETED',
    );
  }
}

void main() {
  testWidgets('챗봇 대화 목록을 표시하고 대화를 연다', (tester) async {
    final repository = FakeChatbotRepository();

    await tester.pumpWidget(
      MaterialApp(home: ChatbotConversationListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('AI 건강 챗봇'), findsOneWidget);

    expect(find.text('검사 결과 질문'), findsOneWidget);

    await tester.tap(find.text('검사 결과 질문'));

    await tester.pumpAndSettle();

    expect(find.text('검사 결과를 설명해 주세요.'), findsOneWidget);

    expect(find.text('확인된 결과를 기준으로 설명해 드릴게요.'), findsOneWidget);
  });

  testWidgets('챗봇 화면에서 메시지를 전송한다', (tester) async {
    final repository = FakeChatbotRepository();

    await tester.pumpWidget(
      MaterialApp(home: ChatbotConversationListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('검사 결과 질문'));

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '추가로 알려주세요.');

    await tester.tap(find.byTooltip('전송'));

    await tester.pumpAndSettle();

    expect(repository.sentCount, 1);
  });
}
