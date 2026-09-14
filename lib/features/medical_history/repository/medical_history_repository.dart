import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../model/medical_timeline.dart';

class MedicalHistoryRepository {
  MedicalHistoryRepository(this.client);

  final ApiClient client;

  static const String path = '/api/patients/me/timeline';

  Future<MedicalTimeline> getTimeline() async {
    final response = await client.dio.get<Map<String, dynamic>>(path);
    final data = response.data;

    if (data == null) {
      throw const FormatException('진료·검사이력 응답이 비어 있습니다.');
    }

    final timeline = MedicalTimeline.fromJson(data);

    final results = [...timeline.results]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return MedicalTimeline(patientId: timeline.patientId, results: results);
  }
}

String medicalHistoryErrorMessage(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      401 => '로그인이 만료됐어요. 다시 로그인해 주세요.',
      403 => '병원기록이 연결된 환자만 진료·검사이력을 확인할 수 있어요.',
      404 => '진료·검사이력을 찾을 수 없어요.',
      _ => '진료·검사이력을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
    };
  }

  if (error is FormatException) {
    return '진료·검사이력 응답 형식을 확인할 수 없어요.';
  }

  return '진료·검사이력을 불러오지 못했어요. 다시 시도해 주세요.';
}
