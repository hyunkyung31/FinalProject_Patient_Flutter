class MedicalTimeline {
  const MedicalTimeline({required this.patientId, required this.results});

  final int patientId;
  final List<MedicalTimelineItem> results;

  factory MedicalTimeline.fromJson(Map<String, dynamic> json) {
    final patientId = json['patient_id'];
    final results = json['results'];

    if (patientId is! num) {
      throw const FormatException('환자 식별정보 형식이 올바르지 않습니다.');
    }

    if (results is! List) {
      throw const FormatException('진료·검사이력 목록 형식이 올바르지 않습니다.');
    }

    return MedicalTimeline(
      patientId: patientId.toInt(),
      results: results
          .map(
            (item) => MedicalTimelineItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class MedicalTimelineItem {
  const MedicalTimelineItem({
    required this.eventType,
    required this.referenceId,
    required this.occurredAt,
    required this.title,
    required this.status,
    required this.summary,
    required this.data,
  });

  final String eventType;
  final int referenceId;
  final DateTime occurredAt;
  final String title;
  final String status;
  final String summary;
  final String data;

  factory MedicalTimelineItem.fromJson(Map<String, dynamic> json) {
    final eventType = json['event_type'];
    final referenceId = json['reference_id'];
    final occurredAt = json['occurred_at'];

    if (eventType is! String || eventType.trim().isEmpty) {
      throw const FormatException('이력 종류가 올바르지 않습니다.');
    }

    if (referenceId is! num) {
      throw const FormatException('이력 식별정보가 올바르지 않습니다.');
    }

    if (occurredAt is! String) {
      throw const FormatException('이력 일시 형식이 올바르지 않습니다.');
    }

    final parsedOccurredAt = DateTime.tryParse(occurredAt);

    if (parsedOccurredAt == null) {
      throw const FormatException('이력 일시를 확인할 수 없습니다.');
    }

    return MedicalTimelineItem(
      eventType: eventType.trim(),
      referenceId: referenceId.toInt(),
      occurredAt: parsedOccurredAt,
      title: _text(json['title']),
      status: _text(json['status']),
      summary: _text(json['summary']),
      data: _text(json['data']),
    );
  }

  DateTime get occurredAtKst =>
      occurredAt.toUtc().add(const Duration(hours: 9));

  static String _text(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
