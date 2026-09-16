import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../model/lab_result.dart';

abstract class LabResultRepository {
  Future<List<LabResult>> getLabResults();
}

abstract class LabResultDetailRepository {
  Future<LabResultDetail> getLabResult(int resultId);

  Future<LabTrend> getLabTrend(String code);
}

class PatientLabResultRepository
    implements LabResultRepository, LabResultDetailRepository {
  PatientLabResultRepository(this.client);

  final ApiClient client;

  @override
  Future<List<LabResult>> getLabResults() async {
    final response = await client.dio.get<Object?>(
      '/api/patient/lab-results/',
      queryParameters: const {'page': 1, 'size': 100},
    );

    final data = response.data;
    if (data is! Map) {
      throw const FormatException('혈액검사 목록 형식이 올바르지 않습니다.');
    }

    final payload = Map<String, dynamic>.from(data);
    final rawResults = payload['results'];

    if (rawResults is! List) {
      throw const FormatException('혈액검사 목록 결과가 올바르지 않습니다.');
    }

    return rawResults
        .whereType<Map>()
        .map((item) => LabResult.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<LabResultDetail> getLabResult(int resultId) async {
    final response = await client.dio.get<Object?>(
      '/api/patient/lab-results/$resultId/',
    );

    final data = response.data;
    if (data is! Map) {
      throw const FormatException('혈액검사 상세 형식이 올바르지 않습니다.');
    }

    return LabResultDetail.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<LabTrend> getLabTrend(String code) async {
    final normalizedCode = code.trim();

    if (normalizedCode.isEmpty) {
      throw const FormatException('검사 항목 코드가 비어 있습니다.');
    }

    final response = await client.dio.get<Object?>(
      '/api/patient/lab-results/trends/',
      queryParameters: {'code': normalizedCode},
    );

    final data = response.data;
    if (data is! Map) {
      throw const FormatException('혈액검사 추이 형식이 올바르지 않습니다.');
    }

    return LabTrend.fromJson(Map<String, dynamic>.from(data));
  }
}

String patientLabResultErrorMessage(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      400 => '혈액검사 요청 정보를 확인해 주세요.',
      401 => '로그인이 만료됐어요. 다시 로그인해 주세요.',
      403 => '혈액검사 결과에 접근할 권한이 없어요.',
      404 => '연결된 혈액검사 결과를 찾을 수 없어요.',
      _ => '혈액검사 결과를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
    };
  }

  if (error is FormatException) {
    return error.message;
  }

  return '혈액검사 결과를 불러오지 못했어요. 다시 시도해 주세요.';
}
