class ReservationChangeRequest {
  const ReservationChangeRequest({
    required this.id,
    required this.reservationId,
    required this.requestedAt,
    required this.status,
    this.reason,
  });
  final int id;
  final int reservationId;
  final DateTime requestedAt;
  final String status;
  final String? reason;
  String get statusLabel => switch (status) {
    'PENDING' => '변경 승인 대기',
    'APPROVED' => '변경 승인 완료',
    'REJECTED' => '변경 반려',
    'CANCELED' => '변경 신청 철회',
    _ => '변경 상태 확인 필요',
  };

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
      reason: json['reason'] as String?,
    );
  }

  String get dateLabel {
    final date = requestedAt.add(const Duration(hours: 9));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}.${two(date.month)}.${two(date.day)} · ${two(date.hour)}:${two(date.minute)}';
  }
}
