import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/patient_reservation.dart';
import '../model/reservation_change_request.dart';
import '../model/booking_options.dart';
import 'package:flutter/foundation.dart';

class ReservationRepository {
  ReservationRepository(this.client);
  final ApiClient client;
  static const path = '/api/patient/reservations/';

  Future<ReservationChangeRequest> requestReservationChange({
    required int reservationId,
    required DateTime requestedAt,
    String reason = '',
  }) async {
    if (!requestedAt.isAfter(DateTime.now().toUtc())) {
      throw ArgumentError('미래의 예약 시간을 선택해 주세요.');
    }
    final response = await client.dio.post<Map<String, dynamic>>(
      '$path$reservationId/change-requests/',
      data: {
        'requested_reserved_at': requestedAt.toUtc().toIso8601String(),
        'reason': reason.trim(),
      },
    );
    if (response.data == null)
      throw const FormatException('변경 요청 응답이 비어 있습니다.');
    final result = ReservationChangeRequest.fromJson(response.data!);
    if (result.reservationId != reservationId)
      throw const FormatException('예약 번호가 일치하지 않습니다.');
    return result;
  }

  Future<List<Map<String, dynamic>>> _list(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    final response = await client.dio.get<Object?>(url, queryParameters: query);
    if (response.data is! List) {
      throw const FormatException('목록 응답 형식이 올바르지 않습니다.');
    }
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<DepartmentOption>> getDepartments() async => (await _list(
    '/api/patient/departments/',
  )).map(DepartmentOption.fromJson).toList();

  Future<List<DoctorOption>> getDoctors(int departmentId) async => (await _list(
    '/api/patient/doctors/',
    query: {'department_id': departmentId},
  )).map(DoctorOption.fromJson).toList();

  Future<List<DoctorCalendarDay>> getCalendar(int doctorId) async {
    // 기기 시간대와 관계없이 한국의 오늘 날짜를 기준으로 조회
    final koreanNow = DateTime.now().toUtc().add(const Duration(hours: 9));

    final firstDay = DateTime(koreanNow.year, koreanNow.month, koreanNow.day);

    final lastDay = firstDay.add(const Duration(days: 90));

    String dateText(DateTime date) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');

      return '${date.year}-$month-$day';
    }

    final response = await client.dio.get<Map<String, dynamic>>(
      '/api/patient/doctors/$doctorId/calendar/',
      queryParameters: {'from': dateText(firstDay), 'to': dateText(lastDay)},
    );

    final results = response.data?['results'];

    if (results is! List) {
      throw const FormatException('진료 일정 응답 형식이 올바르지 않습니다.');
    }

    final days = results
        .map(
          (item) => DoctorCalendarDay.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    days.sort((a, b) => a.date.compareTo(b.date));

    return days;
  }

  Future<List<BookingSlot>> getSlots(int doctorId, {DateTime? date}) async {
    final now = DateTime.now().toUtc();

    String from;
    String to;

    if (date != null) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final dateText = '${date.year}-$month-$day';

      // 선택한 날짜의 한국 시간 00:00부터 23:59:59까지
      from = '${dateText}T00:00:00+09:00';
      to = '${dateText}T23:59:59+09:00';
    } else {
      // 다음 단계에서 화면을 바꾸기 전까지 기존 호출과 호환
      from = now.toIso8601String();
      to = now.add(const Duration(days: 90)).toIso8601String();
    }

    final rows = await _list(
      '/api/patient/doctors/$doctorId/availability/',
      query: {'from': from, 'to': to},
    );

    final slots = rows.map(BookingSlot.fromJson).toList();

    slots.sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return slots;
  }

  Future<bool> hasPatientLink() async {
    final response = await client.dio.get<Map<String, dynamic>>(
      '/api/patients/me/link-status/',
    );
    final linked = response.data?['linked'];
    if (linked is! bool) throw const FormatException('연결 상태를 확인할 수 없습니다.');
    return linked;
  }

  Future<BookingVerification?> getVerification() async {
    final records =
        (await _list('/api/verifications/', query: {'valid_only': true}))
            .map(BookingVerification.fromJson)
            .where((item) => item.isValid(DateTime.now()))
            .toList();
    return records.isEmpty ? null : records.first;
  }

  Future<BookingVerification> verifyFirebasePhone(String idToken) async {
    if (idToken.trim().isEmpty) {
      throw ArgumentError('Firebase ID 토큰이 비어 있습니다.');
    }

    final response = await client.dio.post<Map<String, dynamic>>(
      '/api/verifications/firebase/',
      data: {'id_token': idToken},
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('전화번호 인증 응답이 비어 있습니다.');
    }

    final verification = BookingVerification.fromJson(data);

    if (!verification.isValid(DateTime.now())) {
      throw StateError('사용 가능한 전화번호 인증 기록이 아닙니다.');
    }

    if (verification.verifiedPhoneNumber?.trim().isNotEmpty != true) {
      throw const FormatException('인증된 전화번호가 응답에 없습니다.');
    }

    return verification;
  }

  Future<BookingVerification> completeDevelopmentVerification({
    int? pendingId,
  }) async {
    if (!kDebugMode) throw StateError('개발용 인증은 디버그 모드에서만 사용할 수 있습니다.');
    int id;
    if (pendingId != null) {
      id = pendingId;
    } else {
      final response = await client.dio.post<Map<String, dynamic>>(
        '/api/verifications/',
        data: {'auth_method': 'DEVELOPMENT_TEST'},
      );
      id = response.data!['id'] as int;
    }
    final completed = await client.dio.post<Map<String, dynamic>>(
      '/api/verifications/$id/complete/',
    );
    return BookingVerification.fromJson(completed.data!);
  }

  Future<PatientReservation> createReservation({
    required int doctorId,
    required DateTime reservedAt,
    required String name,
    required String birthDate,
    required String contact,
    int? verificationId,
  }) async {
    final response = await client.dio.post<Map<String, dynamic>>(
      path,
      data: {
        'doctor_id': doctorId,
        'reserved_at': reservedAt.toUtc().toIso8601String(),
        'applicant_name': name,
        'applicant_birth_date': birthDate,
        'applicant_contact': contact,
        'verification_id': ?verificationId,
      },
    );
    return _parse(response.data);
  }

  Future<PatientReservation> getReservation(int id) async {
    final response = await client.dio.get<Map<String, dynamic>>('$path$id/');
    final reservation = _parse(response.data);

    final names = await Future.wait<String?>([
      _getDoctorName(reservation.doctorId),
      _getDepartmentName(reservation.departmentId),
    ]);

    return reservation.withNames(
      doctorName: names[0],
      departmentName: names[1],
    );
  }

  Future<String?> _getDoctorName(int? doctorId) async {
    if (doctorId == null) {
      return null;
    }

    try {
      final response = await client.dio.get<Map<String, dynamic>>(
        '/api/patient/doctors/$doctorId/',
      );

      final name = response.data?['name'];

      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }

      return null;
    } catch (_) {
      // 이름 조회가 실패해도 예약 상세는 표시합니다.
      return null;
    }
  }

  Future<String?> _getDepartmentName(int? departmentId) async {
    if (departmentId == null) {
      return null;
    }

    try {
      final departments = await getDepartments();

      for (final department in departments) {
        if (department.id == departmentId) {
          final name = department.name.trim();
          return name.isEmpty ? null : name;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<PatientReservation>> getReservations() async {
    final response = await client.dio.get<Object?>(path);
    final data = response.data;
    if (data is! List) {
      throw const FormatException('예약 목록 형식이 올바르지 않습니다.');
    }
    return data
        .map(
          (item) => PatientReservation.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<PatientReservation> cancelReservation(int id) async {
    final response = await client.dio.post<Map<String, dynamic>>(
      '$path$id/cancel/',
      data: <String, dynamic>{},
    );
    return _parse(response.data);
  }

  PatientReservation _parse(Map<String, dynamic>? data) {
    if (data == null) throw const FormatException('예약 응답이 비어 있습니다.');
    return PatientReservation.fromJson(data);
  }
}

String reservationErrorMessage(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      401 => '로그인이 만료됐어요. 앱을 다시 시작해 로그인해 주세요.',
      403 => '이 예약에 접근할 권한이 없어요.',
      404 => '예약을 찾을 수 없어요. 목록을 다시 확인해 주세요.',
      _ => '요청을 완료하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.',
    };
  }
  return '예약 정보를 확인하지 못했어요. 다시 시도해 주세요.';
}
