import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../model/patient_ai_result.dart';

// 환자에게 공개된 AI 결과를 조회하는 Repository
class PatientAIResultRepository {
  PatientAIResultRepository(this.client);

  final ApiClient client;

  static const String path = '/api/patient/ai-results/';

  // 공개된 AI 결과 목록 조회
  Future<List<PatientAIResult>> getResults({
    DateTime? date,
    String? resultType,
  }) async {
    final query = <String, dynamic>{};

    if (date != null) {
      query['date'] = _dateText(date);
    }

    if (resultType != null && resultType.trim().isNotEmpty) {
      query['type'] = resultType.trim();
    }

    final response = await client.dio.get<Object?>(
      path,
      queryParameters: query.isEmpty ? null : query,
    );

    final data = response.data;

    if (kDebugMode) {
      debugPrint('[AI_RESULT_DEBUG] baseUrl=${client.dio.options.baseUrl}');
      debugPrint('[AI_RESULT_DEBUG] status=${response.statusCode}');

      if (data is List) {
        debugPrint('[AI_RESULT_DEBUG] count=${data.length}');

        for (final item in data.whereType<Map>()) {
          debugPrint(
            "[AI_RESULT_DEBUG] "
            "id=${item['id']} "
            "type=${item['analysis_type']} "
            "status=${item['status']}",
          );
        }
      } else {
        debugPrint('[AI_RESULT_DEBUG] responseType=${data.runtimeType}');
      }
    }

    if (data is! List) {
      throw const FormatException('AI 결과 목록 형식이 올바르지 않습니다.');
    }

    final results = data
        .whereType<Map>()
        .map(
          (item) => PatientAIResult.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    results.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

    return results;
  }

  // 선택한 AI 결과 상세 조회
  Future<PatientAIResult> getResult(int resultId) async {
    final response = await client.dio.get<Map<String, dynamic>>(
      '$path$resultId/',
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('AI 결과 상세 응답이 비어 있습니다.');
    }

    return PatientAIResult.fromJson(data);
  }
}

// AI 결과 API 오류를 환자용 안내 문구로 변환
String patientAIResultErrorMessage(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      401 => '로그인이 만료됐어요. 다시 로그인해 주세요.',
      403 => '아직 공개되지 않은 AI 결과예요.',
      404 => '확인할 수 있는 AI 결과를 찾지 못했어요.',
      409 => '병원 환자정보 연결이 필요해요.',
      _ => 'AI 결과를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
    };
  }

  if (error is FormatException) {
    return 'AI 결과 형식을 확인하지 못했어요.';
  }

  return 'AI 결과를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
}

// API 날짜 필터용 yyyy-MM-dd 문자열 생성
String _dateText(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}
