class PatientNotification {
  const PatientNotification({
    required this.recipientId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.type,
    this.referenceType,
    this.referenceId,
  });
  final int recipientId;
  final String title, body, type;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceType;
  final int? referenceId;

  factory PatientNotification.fromJson(Map<String, dynamic> json) {
    final n = json['notification'];
    if (json['id'] is! int ||
        json['is_read'] is! bool ||
        n is! Map ||
        n['title'] is! String ||
        n['body'] is! String ||
        n['created_at'] is! String ||
        n['notification_type'] is! String) {
      throw const FormatException('알림 응답 형식을 확인하지 못했어요.');
    }
    return PatientNotification(
      recipientId: json['id'] as int,
      title: n['title'] as String,
      body: n['body'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(n['created_at'] as String).toUtc(),
      type: n['notification_type'] as String,
      referenceType: n['reference_type'] as String?,
      referenceId: n['reference_id'] as int?,
    );
  }
  PatientNotification read() => PatientNotification(
    recipientId: recipientId,
    title: title,
    body: body,
    isRead: true,
    createdAt: createdAt,
    type: type,
    referenceType: referenceType,
    referenceId: referenceId,
  );
  String get dateLabel {
    final d = createdAt.add(const Duration(hours: 9));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class NotificationPage {
  const NotificationPage(this.items, this.hasNext, this.page);
  final List<PatientNotification> items;
  final bool hasNext;
  final int page;
}
