import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../model/patient_prescription.dart';

class PatientPrescriptionRepository {
  PatientPrescriptionRepository(this.client);

  final ApiClient client;

  Future<List<PatientCurrentMedication>> getCurrentMedications() async {
    final response = await client.dio.get<Object?>(
      '/api/patient/current-medications/',
    );

    final data = response.data;
    if (data is! List) {
      throw const FormatException('현재 복용약 목록 형식이 올바르지 않습니다.');
    }

    return data
        .map(
          (item) => PatientCurrentMedication.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((item) => item.isActive)
        .toList();
  }

  Future<List<PatientPrescription>> getPrescriptions() async {
    final response = await client.dio.get<Object?>(
      '/api/patient/prescriptions/',
      queryParameters: const {'status': 'SIGNED'},
    );

    final data = response.data;
    if (data is! List) {
      throw const FormatException('처방 목록 형식이 올바르지 않습니다.');
    }

    final prescriptions = data
        .map(
          (item) => PatientPrescription.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((item) => item.isSigned)
        .toList();

    prescriptions.sort((a, b) => b.prescribedAt.compareTo(a.prescribedAt));

    return prescriptions;
  }

  Future<PatientPrescriptionDetail> getPrescription(int prescriptionId) async {
    final response = await client.dio.get<Map<String, dynamic>>(
      '/api/patient/prescriptions/$prescriptionId/',
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('처방 상세 응답이 비어 있습니다.');
    }

    final detail = PatientPrescriptionDetail.fromJson(data);

    if (!detail.prescription.isSigned) {
      throw StateError('확정되지 않은 처방은 환자에게 표시할 수 없습니다.');
    }

    return detail;
  }
}

String patientPrescriptionErrorMessage(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      401 => '로그인이 만료됐어요. 앱을 다시 시작해 로그인해 주세요.',
      403 => '이 처방에 접근할 권한이 없어요.',
      404 => '처방 정보를 찾을 수 없어요.',
      409 => '병원 진료기록 연결 후 처방을 확인할 수 있어요.',
      _ => '처방 정보를 불러오지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.',
    };
  }

  if (error is FormatException) {
    return error.message;
  }

  if (error is StateError) {
    return '확정된 처방만 확인할 수 있어요.';
  }

  return '처방 정보를 확인하지 못했어요. 다시 시도해 주세요.';
}
