import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../model/patient_report.dart';

class PatientReportRepository {
  PatientReportRepository(this.client);

  final ApiClient client;

  // 공개된 최종 결과 목록 조회
  Future<List<PatientReleasedResult>> getResults() async {
    final response = await client.dio.get<dynamic>('/api/patient/results/');

    final data = response.data;

    if (data is! List) {
      throw const FormatException('최종 보고서 목록 형식이 올바르지 않습니다.');
    }

    final results = data
        .whereType<Map>()
        .map(
          (item) =>
              PatientReleasedResult.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    results.sort((a, b) => b.releasedAt.compareTo(a.releasedAt));

    return results;
  }

  // 공개된 최종 결과 상세 조회
  Future<PatientReleasedResultDetail> getResult(int resultId) async {
    final response = await client.dio.get<dynamic>(
      '/api/patient/results/$resultId/',
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('최종 보고서 상세 형식이 올바르지 않습니다.');
    }

    final detail = PatientReleasedResultDetail.fromJson(
      Map<String, dynamic>.from(data),
    );

    // 환자용 보고서만 앱에 전달
    return PatientReleasedResultDetail(
      medicalResult: detail.medicalResult,
      reports: patientOnlyReports(detail.reports),
    );
  }

  // 공개된 환자용 보고서 목록 조회
  Future<List<PatientReport>> getReports(int resultId) async {
    final response = await client.dio.get<dynamic>(
      '/api/patient/results/$resultId/reports/',
    );

    final data = response.data;

    if (data is! List) {
      throw const FormatException('보고서 목록 형식이 올바르지 않습니다.');
    }

    return data
        .whereType<Map>()
        .map((item) => PatientReport.fromJson(Map<String, dynamic>.from(item)))
        .where((report) => report.isPatientReport)
        .toList();
  }

  // 환자용 PDF 다운로드 정보 조회
  Future<PatientReportDownload> getDownload(int reportId) async {
    final response = await client.dio.get<dynamic>(
      '/api/patient/reports/$reportId/download/',
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('보고서 다운로드 정보가 올바르지 않습니다.');
    }

    final download = PatientReportDownload.fromJson(
      Map<String, dynamic>.from(data),
    );

    if (!download.report.isPatientReport) {
      throw const FormatException('환자용 보고서가 아닙니다.');
    }

    return download;
  }
}

String patientReportErrorMessage(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      401 => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      403 => '아직 공개되지 않은 보고서입니다.',
      404 => '보고서를 찾을 수 없습니다.',
      409 => '병원기록 연결 후 보고서를 확인할 수 있습니다.',
      _ => '보고서를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
    };
  }

  if (error is FormatException) {
    return error.message;
  }

  return '보고서를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
