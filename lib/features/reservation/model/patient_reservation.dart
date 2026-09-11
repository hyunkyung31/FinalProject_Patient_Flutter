class PatientReservation {
  const PatientReservation({
    required this.id,
    required this.reservedAt,
    required this.status,
    required this.applicantName,
    this.cancelReason,
    this.doctorId,
    this.departmentId,
    this.doctorName,
    this.departmentName,
  });

  final int id;
  final DateTime reservedAt;
  final String status;
  final String applicantName;
  final String? cancelReason;
  final int? doctorId;
  final int? departmentId;
  final String? doctorName;
  final String? departmentName;

  factory PatientReservation.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final date = json['reserved_at'];
    final status = json['status'];
    final name = json['applicant_name'];
    if (id is! int ||
        date is! String ||
        status is! String ||
        name is! String ||
        !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(date)) {
      throw const FormatException('예약 응답 형식이 올바르지 않습니다.');
    }
    return PatientReservation(
      id: id,
      reservedAt: DateTime.parse(date).toUtc(),
      status: status,
      applicantName: name,
      cancelReason: json['cancel_reason'] as String?,
      doctorId: json['doctor'] as int?,
      departmentId: json['department'] as int?,
    );
  }
  PatientReservation withNames({
    String? doctorName,
    String? departmentName,
  }) {
    return PatientReservation(
      id: id,
      reservedAt: reservedAt,
      status: status,
      applicantName: applicantName,
      cancelReason: cancelReason,
      doctorId: doctorId,
      departmentId: departmentId,
      doctorName: doctorName ?? this.doctorName,
      departmentName: departmentName ?? this.departmentName,
    );
  }

  String get statusLabel => switch (status) {
    'REQUESTED' => '승인 대기',
    'ACCEPTED' => '예약 승인',
    'CANCELED' => '예약 취소',
    _ => '상태 확인 필요',
  };
  bool isPast(DateTime now) =>
      status == 'CANCELED' || reservedAt.isBefore(now.toUtc());
  bool canCancel(DateTime now) =>
      !isPast(now) && (status == 'REQUESTED' || status == 'ACCEPTED');

  // 한국 병원 예약 시각. 기기 시간대가 UTC여도 한국 시간으로 표시합니다.
  String get dateLabel {
    final date = reservedAt.add(const Duration(hours: 9));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}.${two(date.month)}.${two(date.day)} · ${two(date.hour)}:${two(date.minute)}';
  }
}
