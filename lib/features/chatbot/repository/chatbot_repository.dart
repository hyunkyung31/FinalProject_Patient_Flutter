import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../model/chatbot_conversation.dart';
import '../model/chatbot_message.dart';

class ChatbotRepository {
  ChatbotRepository(this.client);

  final ApiClient client;

  static const _basePath = '/api/patient/chatbot/conversations/';

  Future<ChatbotConversationPage> getConversations({
    String? status,
    int page = 1,
  }) async {
    final response = await client.dio.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: {
        'page': page,
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('챗봇 대화 목록 응답이 비어 있습니다.');
    }

    return ChatbotConversationPage.fromJson(data);
  }

  Future<ChatbotConversation> createConversation({String? title}) async {
    final response = await client.dio.post<Map<String, dynamic>>(
      _basePath,
      data: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('챗봇 대화 생성 응답이 비어 있습니다.');
    }

    return ChatbotConversation.fromJson(data);
  }

  Future<ChatbotConversationDetail> getConversation(int conversationId) async {
    final response = await client.dio.get<Map<String, dynamic>>(
      '$_basePath$conversationId/',
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('챗봇 대화 상세 응답이 비어 있습니다.');
    }

    return ChatbotConversationDetail.fromJson(data);
  }

  Future<ChatbotSendResult> sendMessage({
    required int conversationId,
    required String messageText,
  }) async {
    final text = messageText.trim();

    if (text.isEmpty) {
      throw ArgumentError('메시지를 입력해 주세요.');
    }

    final response = await client.dio.post<Map<String, dynamic>>(
      '$_basePath$conversationId/messages/',
      data: {'message_text': text},
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('챗봇 메시지 응답이 비어 있습니다.');
    }

    return ChatbotSendResult.fromJson(data);
  }

  Future<ChatbotConversation> closeConversation(int conversationId) async {
    final response = await client.dio.post<Map<String, dynamic>>(
      '$_basePath$conversationId/close/',
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('챗봇 대화 종료 응답이 비어 있습니다.');
    }

    return ChatbotConversation.fromJson(data);
  }
}

String chatbotErrorMessage(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 400) {
      return '입력한 내용을 확인해 주세요.';
    }

    if (statusCode == 401) {
      return '로그인이 만료됐어요. 다시 로그인해 주세요.';
    }

    if (statusCode == 403) {
      return '챗봇을 사용할 권한이 없어요.';
    }

    if (statusCode == 404) {
      return '대화 정보를 찾을 수 없어요.';
    }

    if (statusCode == 409) {
      return '환자 진료기록 연결이 필요하거나 종료된 대화예요.';
    }

    if (statusCode == 429) {
      return '요청이 많아요. 잠시 후 다시 시도해 주세요.';
    }

    return '챗봇에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.';
  }

  if (error is ArgumentError) {
    return error.message?.toString() ?? '메시지를 입력해 주세요.';
  }

  if (error is FormatException) {
    return error.message;
  }

  return '챗봇을 이용하는 중 문제가 발생했어요.';
}
