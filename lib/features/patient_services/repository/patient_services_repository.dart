import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class PatientPage {
  const PatientPage(this.items, this.hasNext);
  final List<Map<String, dynamic>> items;
  final bool hasNext;
}

class PatientServicesRepository {
  PatientServicesRepository(this.client);
  final ApiClient client;

  Future<Map<String, dynamic>> _object(String path) async {
    final response = await client.dio.get<Object?>(path);
    if (response.data is! Map) {
      throw const FormatException('서버 응답 형식을 확인하지 못했어요.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<PatientPage> _page(String path, int page) async {
    final response = await client.dio.get<Object?>(
      path,
      queryParameters: {'page': page},
    );
    final data = response.data;
    final rows = data is Map ? data['results'] : data;
    if (rows is! List) {
      throw const FormatException('목록 응답 형식을 확인하지 못했어요.');
    }
    return PatientPage(
      rows.map((row) => Map<String, dynamic>.from(row as Map)).toList(),
      data is Map && data['next'] != null,
    );
  }

  Future<Map<String, dynamic>> profile() => _object('/api/patients/me/');
  Future<Map<String, dynamic>> linkStatus() =>
      _object('/api/patients/me/link-status/');
  Future<PatientPage> changes(int page) =>
      _page('/api/patients/me/information-change-requests/', page);
  Future<PatientPage> documents(int page) =>
      _page('/api/consent-documents/', page);
  Future<PatientPage> consents(int page) => _page('/api/consents/', page);

  Future<List<Map<String, dynamic>>> requiredConsentDocuments() async {
    final documents = await _allPages('/api/consent-documents/');
    final consents = await _allPages('/api/consents/');
    final consentedDocumentIds = <int>{
      for (final consent in consents)
        if (consent['status'] == 'CONSENTED' &&
            consent['consent_document'] is Map &&
            consent['consent_document']['id'] is int)
          consent['consent_document']['id'] as int,
    };
    final required = <Map<String, dynamic>>[];
    for (final document in documents) {
      if (document['consent_type'] != 'REQUIRED' ||
          document['is_active'] != true) {
        continue;
      }
      if (document['id'] is! int ||
          document['title'] is! String ||
          document['content_text'] is! String) {
        throw const FormatException('필수 동의 문서 형식을 확인하지 못했어요.');
      }
      if (!consentedDocumentIds.contains(document['id'])) {
        required.add(document);
      }
    }
    return required;
  }

  Future<List<Map<String, dynamic>>> _allPages(String path) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1; ; page++) {
      final result = await _page(path, page);
      rows.addAll(result.items);
      if (!result.hasNext) return rows;
    }
  }

  Future<void> requestLink(int verificationId) async {
    await client.dio.post<Object?>(
      '/api/record-link-request/',
      data: {'verification_id': verificationId},
    );
  }

  Future<void> requestChange(String field, String value, String reason) async {
    if (!{'name', 'birth_date', 'gender', 'contact'}.contains(field)) {
      throw ArgumentError('지원되지 않는 변경 항목입니다.');
    }
    await client.dio.post<Object?>(
      '/api/patients/me/information-change-requests/',
      data: {'field_name': field, 'requested_value': value, 'reason': reason},
    );
  }

  Future<void> consent(int documentId) async {
    await client.dio.post<Object?>(
      '/api/consents/',
      data: {'consent_document_id': documentId, 'consented': true},
    );
  }

  Future<void> withdraw(int consentId, String reason) async {
    if (reason.trim().isEmpty) throw ArgumentError('철회 사유를 입력해 주세요.');
    await client.dio.post<Object?>(
      '/api/consents/$consentId/withdraw/',
      data: {'reason': reason.trim()},
    );
  }
}

String patientServiceError(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      401 => '로그인이 만료됐어요. 다시 로그인해 주세요.',
      403 => '이 기능에 접근할 권한이 없어요.',
      404 => '요청한 정보를 찾을 수 없어요.',
      409 => '연결된 병원기록이 없거나 현재 상태에서 처리할 수 없어요.',
      400 => '입력 내용과 현재 처리 상태를 확인해 주세요.',
      _ => '서버에 연결하지 못했어요. 잠시 후 다시 확인해 주세요.',
    };
  }
  return '정보를 확인하지 못했어요. 다시 시도해 주세요.';
}
