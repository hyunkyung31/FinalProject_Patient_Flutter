class PatientMedicalResult {
  const PatientMedicalResult({
    required this.id,
    required this.encounterId,
    required this.patientId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.finalAssessmentId,
    this.summary,
    this.conclusion,
  });

  final int id;
  final int encounterId;
  final int patientId;
  final int? finalAssessmentId;
  final String? summary;
  final String? conclusion;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PatientMedicalResult.fromJson(Map<String, dynamic> json) {
    return PatientMedicalResult(
      id: _requiredInt(json['id'], 'id'),
      encounterId: _requiredInt(json['encounter'], 'encounter'),
      patientId: _requiredInt(json['patient'], 'patient'),
      finalAssessmentId: _nullableInt(json['final_assessment']),
      summary: json['summary']?.toString(),
      conclusion: json['conclusion']?.toString(),
      status: json['status']?.toString() ?? '',
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
    );
  }
}

class PatientReleasedResult {
  const PatientReleasedResult({
    required this.medicalResult,
    required this.releasedAt,
    required this.releaseIds,
  });

  final PatientMedicalResult medicalResult;
  final DateTime releasedAt;
  final List<int> releaseIds;

  factory PatientReleasedResult.fromJson(Map<String, dynamic> json) {
    final medicalResultJson = json['medical_result'];

    if (medicalResultJson is! Map<String, dynamic>) {
      throw const FormatException('medical_result 형식이 올바르지 않습니다.');
    }

    return PatientReleasedResult(
      medicalResult: PatientMedicalResult.fromJson(medicalResultJson),
      releasedAt: _requiredDateTime(json['released_at'], 'released_at'),
      releaseIds: _parseIntList(json['release_ids']),
    );
  }
}

class PatientReport {
  const PatientReport({
    required this.id,
    required this.reportVersionId,
    required this.fileAssetId,
    required this.reportName,
    required this.reportType,
    required this.createdAt,
    required this.status,
    this.withdrawnById,
    this.withdrawnAt,
    this.withdrawReason,
  });

  final int id;
  final int reportVersionId;
  final int fileAssetId;
  final int? withdrawnById;
  final String reportName;
  final String reportType;
  final DateTime createdAt;
  final String status;
  final DateTime? withdrawnAt;
  final String? withdrawReason;

  bool get isPatientReport => reportType.toUpperCase() == 'PATIENT';

  factory PatientReport.fromJson(Map<String, dynamic> json) {
    return PatientReport(
      id: _requiredInt(json['id'], 'id'),
      reportVersionId: _requiredInt(json['report_version'], 'report_version'),
      fileAssetId: _requiredInt(json['file_asset'], 'file_asset'),
      withdrawnById: _nullableInt(json['withdrawn_by']),
      reportName: json['report_name']?.toString() ?? '',
      reportType: json['report_type']?.toString() ?? '',
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      status: json['status']?.toString() ?? '',
      withdrawnAt: _nullableDateTime(json['withdrawn_at']),
      withdrawReason: json['withdraw_reason']?.toString(),
    );
  }
}

class PatientReleasedResultDetail {
  const PatientReleasedResultDetail({
    required this.medicalResult,
    required this.reports,
  });

  final PatientMedicalResult medicalResult;
  final List<PatientReport> reports;

  factory PatientReleasedResultDetail.fromJson(Map<String, dynamic> json) {
    final medicalResultJson = json['medical_result'];

    if (medicalResultJson is! Map<String, dynamic>) {
      throw const FormatException('medical_result 형식이 올바르지 않습니다.');
    }

    return PatientReleasedResultDetail(
      medicalResult: PatientMedicalResult.fromJson(medicalResultJson),
      reports: _parseReports(json['reports']),
    );
  }
}

class PatientReportDownload {
  const PatientReportDownload({required this.report, required this.file});

  final PatientReport report;
  final PatientReportFile file;

  factory PatientReportDownload.fromJson(Map<String, dynamic> json) {
    final reportJson = json['report'];
    final fileJson = json['file'];

    if (reportJson is! Map<String, dynamic>) {
      throw const FormatException('report 형식이 올바르지 않습니다.');
    }

    if (fileJson is! Map<String, dynamic>) {
      throw const FormatException('file 형식이 올바르지 않습니다.');
    }

    return PatientReportDownload(
      report: PatientReport.fromJson(reportJson),
      file: PatientReportFile.fromJson(fileJson),
    );
  }
}

class PatientReportFile {
  const PatientReportFile({
    required this.fileId,
    required this.storageBackend,
    required this.integrationStatus,
    this.bucketName,
    this.objectKey,
    this.mimeType,
    this.checksum,
    this.sizeBytes,
    this.downloadUrl,
  });

  final int fileId;
  final String storageBackend;
  final String? bucketName;
  final String? objectKey;
  final String? mimeType;
  final String? checksum;
  final int? sizeBytes;
  final String? downloadUrl;
  final String integrationStatus;

  bool get canDownload =>
      integrationStatus == 'CONFIGURED' &&
      downloadUrl != null &&
      downloadUrl!.trim().isNotEmpty;

  factory PatientReportFile.fromJson(Map<String, dynamic> json) {
    return PatientReportFile(
      fileId: _requiredInt(json['file_id'], 'file_id'),
      storageBackend: json['storage_backend']?.toString() ?? '',
      bucketName: json['bucket_name']?.toString(),
      objectKey: json['object_key']?.toString(),
      mimeType: json['mime_type']?.toString(),
      checksum: json['checksum']?.toString(),
      sizeBytes: _nullableInt(json['size_bytes']),
      downloadUrl: json['download_url']?.toString(),
      integrationStatus: json['download_integration_status']?.toString() ?? '',
    );
  }
}

List<PatientReport> _parseReports(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => PatientReport.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<int> _parseIntList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value.map(_nullableInt).whereType<int>().toList();
}

int _requiredInt(dynamic value, String fieldName) {
  final parsed = _nullableInt(value);

  if (parsed == null) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }

  return parsed;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString());
}

DateTime _requiredDateTime(dynamic value, String fieldName) {
  final parsed = _nullableDateTime(value);

  if (parsed == null) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }

  return parsed;
}

DateTime? _nullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString())?.toLocal();
}

// 환자 앱에는 PATIENT 보고서만 전달
List<PatientReport> patientOnlyReports(Iterable<PatientReport> reports) {
  return reports.where((report) => report.isPatientReport).toList();
}
