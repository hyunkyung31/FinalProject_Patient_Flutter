import 'chatbot_conversation.dart';

class ChatbotMessage {
  const ChatbotMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.messageText,
    required this.messageType,
    required this.createdAt,
    this.safetyStatus,
  });

  final int id;
  final int conversationId;
  final String senderType;
  final String messageText;
  final String messageType;
  final String? safetyStatus;
  final DateTime createdAt;

  String get normalizedSenderType {
    final value = senderType.toUpperCase();

    // Backend 임시 ASSISTANT 값을 CHATBOT으로 처리
    if (value == 'ASSISTANT') {
      return 'CHATBOT';
    }

    return value;
  }

  String? get normalizedSafetyStatus {
    final value = safetyStatus?.toUpperCase();

    // Backend 임시 SAFE 값을 PASS로 처리
    if (value == 'SAFE') {
      return 'PASS';
    }

    // PENDING은 최종 안전 상태가 아님
    if (value == 'PENDING') {
      return null;
    }

    return value;
  }

  bool get isPatient => normalizedSenderType == 'PATIENT';

  bool get isChatbot => normalizedSenderType == 'CHATBOT';

  bool get isSystem => normalizedSenderType == 'SYSTEM';

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      id: _requiredInt(json['id']),
      conversationId: _requiredInt(json['conversation']),
      senderType: _requiredString(json['sender_type']),
      messageText: _requiredString(json['message_text']),
      messageType: _requiredString(json['message_type']),
      safetyStatus: _asString(json['safety_status']),
      createdAt: _requiredDateTime(json['created_at']),
    );
  }
}

class ChatbotConversationDetail {
  const ChatbotConversationDetail({
    required this.conversation,
    required this.messages,
  });

  final ChatbotConversation conversation;
  final List<ChatbotMessage> messages;

  factory ChatbotConversationDetail.fromJson(Map<String, dynamic> json) {
    final rawConversation = json['conversation'];
    final rawMessages = json['messages'];

    if (rawConversation is! Map) {
      throw const FormatException('챗봇 대화 정보 형식이 올바르지 않습니다.');
    }

    if (rawMessages is! List) {
      throw const FormatException('챗봇 메시지 목록 형식이 올바르지 않습니다.');
    }

    return ChatbotConversationDetail(
      conversation: ChatbotConversation.fromJson(
        Map<String, dynamic>.from(rawConversation),
      ),
      messages: rawMessages
          .map(
            (item) =>
                ChatbotMessage.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class ChatbotSendResult {
  const ChatbotSendResult({
    required this.patientMessage,
    required this.integrationStatus,
    this.assistantMessage,
    this.detail,
  });

  final ChatbotMessage patientMessage;
  final ChatbotMessage? assistantMessage;
  final String integrationStatus;
  final String? detail;

  bool get completed {
    return integrationStatus.toUpperCase() == 'COMPLETED' &&
        assistantMessage != null;
  }

  factory ChatbotSendResult.fromJson(Map<String, dynamic> json) {
    final rawPatientMessage = json['patient_message'];
    final rawAssistantMessage = json['assistant_message'];

    if (rawPatientMessage is! Map) {
      throw const FormatException('환자 메시지 응답 형식이 올바르지 않습니다.');
    }

    return ChatbotSendResult(
      patientMessage: ChatbotMessage.fromJson(
        Map<String, dynamic>.from(rawPatientMessage),
      ),
      assistantMessage: rawAssistantMessage is Map
          ? ChatbotMessage.fromJson(
              Map<String, dynamic>.from(rawAssistantMessage),
            )
          : null,
      integrationStatus: _asString(json['integration_status']) ?? 'UNKNOWN',
      detail: _asString(json['detail']),
    );
  }
}

String? _asString(Object? value) {
  if (value == null) return null;

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _requiredString(Object? value) {
  final text = _asString(value);

  if (text == null) {
    throw const FormatException('필수 문자열 값이 없습니다.');
  }

  return text;
}

int _requiredInt(Object? value) {
  if (value is int) return value;

  final parsed = int.tryParse(value?.toString() ?? '');

  if (parsed == null) {
    throw const FormatException('필수 숫자 값이 없습니다.');
  }

  return parsed;
}

DateTime _requiredDateTime(Object? value) {
  final text = _asString(value);
  final parsed = text == null ? null : DateTime.tryParse(text);

  if (parsed == null) {
    throw const FormatException('필수 날짜 값이 없습니다.');
  }

  return parsed;
}
