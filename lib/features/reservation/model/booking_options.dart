class DepartmentOption {
  const DepartmentOption(this.id, this.name);
  final int id;
  final String name;
  factory DepartmentOption.fromJson(Map<String, dynamic> json) =>
      DepartmentOption(json['id'] as int, json['name'] as String);
}

class DoctorOption {
  const DoctorOption(this.id, this.name, this.title);
  final int id;
  final String name;
  final String? title;
  factory DoctorOption.fromJson(Map<String, dynamic> json) => DoctorOption(
    json['id'] as int,
    json['name'] as String,
    json['title'] as String?,
  );
}

class BookingSlot {
  const BookingSlot({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.isAvailable,
    required this.remainingCapacity,
  });

  final int id;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isAvailable;
  final int remainingCapacity;

  factory BookingSlot.fromJson(Map<String, dynamic> json) {
    return BookingSlot(
      id: json['id'] as int,
      startsAt: DateTime.parse(json['starts_at'] as String).toUtc(),
      endsAt: DateTime.parse(json['ends_at'] as String).toUtc(),
      isAvailable: json['is_available'] as bool,
      remainingCapacity: json['remaining_capacity'] as int,
    );
  }

  // 기존 코드가 available을 사용하는 동안 호환 유지
  bool get available => isAvailable;

  DateTime get koreanDate {
    final date = startsAt.add(const Duration(hours: 9));
    return DateTime(date.year, date.month, date.day);
  }

  String get timeLabel {
    final start = startsAt.add(const Duration(hours: 9));
    final end = endsAt.add(const Duration(hours: 9));

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(start.hour)}:${two(start.minute)}'
        '–${two(end.hour)}:${two(end.minute)}';
  }

  // 기존 화면에서 사용하는 날짜 + 시간 표시
  String get label {
    final date = koreanDate;
    return '${date.month}/${date.day} $timeLabel';
  }
}

class BookingVerification {
  const BookingVerification(
    this.id,
    this.expiresAt,
    this.verified,
    this.reusable, {
    this.verifiedPhoneNumber,
  });

  final int id;
  final DateTime? expiresAt;
  final bool verified;
  final bool reusable;

  // Firebase에서 검증한 전화번호입니다.
  // 예: +821012345678
  final String? verifiedPhoneNumber;

  factory BookingVerification.fromJson(Map<String, dynamic> json) {
    return BookingVerification(
      json['id'] as int,
      json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String).toUtc(),
      json['verification_status'] == 'VERIFIED',
      json['is_reusable'] == true || json['is_reusable'] == 'true',
      verifiedPhoneNumber: json['verified_phone_number'] as String?,
    );
  }

  bool isValid(DateTime now) {
    return verified &&
        reusable &&
        (expiresAt == null || expiresAt!.isAfter(now.toUtc()));
  }
}

class DoctorCalendarDay {
  const DoctorCalendarDay({
    required this.date,
    required this.label,
    required this.bookingStatus,
    required this.isBookingDay,
  });

  final DateTime date;
  final String label;
  final String bookingStatus;
  final bool isBookingDay;

  factory DoctorCalendarDay.fromJson(Map<String, dynamic> json) {
    final dateText = json['date'] as String;
    final parts = dateText.split('-');

    return DoctorCalendarDay(
      date: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
      label: json['label'] as String,
      bookingStatus: json['booking_status'] as String,
      isBookingDay: json['is_booking_day'] as bool,
    );
  }
}
