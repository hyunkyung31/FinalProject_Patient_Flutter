class ReservationChangeRequest {
  const ReservationChangeRequest({
    required this.id,
    required this.reservationId,
    required this.requestedAt,
    required this.status,
  });
  final int id;
  final int reservationId;
  final DateTime requestedAt;
  final String status;

  factory ReservationChangeRequest.fromJson(Map<String, dynamic> json) {
    final date = json['requested_reserved_at'];
    if (json['id'] is! int ||
        json['reservation'] is! int ||
        json['status'] is! String ||
        date is! String ||
        !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(date)) {
      throw const FormatException('예약 변경 응답을 확인하지 못했어요.');
    }
    return ReservationChangeRequest(
      id: json['id'] as int,
      reservationId: json['reservation'] as int,
      requestedAt: DateTime.parse(date).toUtc(),
      status: json['status'] as String,
    );
  }

  String get dateLabel {
    final date = requestedAt.add(const Duration(hours: 9));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}.${two(date.month)}.${two(date.day)} · ${two(date.hour)}:${two(date.minute)}';
  }
}
