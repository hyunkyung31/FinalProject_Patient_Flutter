class ChatbotConversation {
  const ChatbotConversation({
    required this.id,
    required this.status,
    required this.startedAt,
    this.title,
    this.endedAt,
  });

  final int id;
  final String? title;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  String get displayTitle {
    final value = title?.trim();
    return value == null || value.isEmpty ? '새 대화' : value;
  }

  factory ChatbotConversation.fromJson(Map<String, dynamic> json) {
    return ChatbotConversation(
      id: _requiredInt(json['id']),
      title: _asString(json['title']),
      status: _asString(json['status']) ?? 'ACTIVE',
      startedAt: _requiredDateTime(json['started_at']),
      endedAt: _asDateTime(json['ended_at']),
    );
  }
}

class ChatbotConversationPage {
  const ChatbotConversationPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
    required this.results,
  });

  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;
  final List<ChatbotConversation> results;

  factory ChatbotConversationPage.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];

    if (rawResults is! List) {
      throw const FormatException('챗봇 대화 목록 형식이 올바르지 않습니다.');
    }

    return ChatbotConversationPage(
      page: _requiredInt(json['page']),
      pageSize: _requiredInt(json['page_size']),
      total: _requiredInt(json['total']),
      hasNext: json['has_next'] == true,
      results: rawResults
          .map(
            (item) => ChatbotConversation.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

String? _asString(Object? value) {
  if (value == null) return null;

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
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
  final parsed = _asDateTime(value);

  if (parsed == null) {
    throw const FormatException('필수 날짜 값이 없습니다.');
  }

  return parsed;
}

DateTime? _asDateTime(Object? value) {
  final text = _asString(value);
  return text == null ? null : DateTime.tryParse(text);
}
