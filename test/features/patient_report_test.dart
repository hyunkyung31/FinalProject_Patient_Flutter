import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_patient/features/patient_report/model/patient_report.dart';

void main() {
  group('Patient report model', () {
    test('released result parses API response', () {
      final result = PatientReleasedResult.fromJson({
        'medical_result': {
          'id': 10,
          'encounter': 20,
          'patient': 30,
          'final_assessment': 40,
          'summary': '검사 결과를 종합한 요약입니다.',
          'conclusion': '의료진의 최종 판단입니다.',
          'status': 'RELEASED',
          'created_at': '2026-09-10T01:00:00Z',
          'updated_at': '2026-09-12T01:00:00Z',
        },
        'released_at': '2026-09-12T02:00:00Z',
        'release_ids': [101, 102],
      });

      expect(result.medicalResult.id, 10);
      expect(result.medicalResult.status, 'RELEASED');
      expect(result.releaseIds, [101, 102]);
      expect(result.medicalResult.summary, '검사 결과를 종합한 요약입니다.');
    });

    test('PATIENT report is recognized as patient report', () {
      final report = PatientReport.fromJson({
        'id': 1,
        'report_version': 11,
        'file_asset': 21,
        'withdrawn_by': null,
        'report_name': 'patient-report.pdf',
        'report_type': 'PATIENT',
        'created_at': '2026-09-12T02:00:00Z',
        'status': 'FINAL',
        'withdrawn_at': null,
        'withdraw_reason': null,
      });

      expect(report.isPatientReport, isTrue);
    });

    test('CLINICAL report is blocked from patient report list', () {
      final reports = [
        PatientReport.fromJson({
          'id': 1,
          'report_version': 11,
          'file_asset': 21,
          'withdrawn_by': null,
          'report_name': 'patient-report.pdf',
          'report_type': 'PATIENT',
          'created_at': '2026-09-12T02:00:00Z',
          'status': 'FINAL',
          'withdrawn_at': null,
          'withdraw_reason': null,
        }),
        PatientReport.fromJson({
          'id': 2,
          'report_version': 12,
          'file_asset': 22,
          'withdrawn_by': null,
          'report_name': 'clinical-report.pdf',
          'report_type': 'CLINICAL',
          'created_at': '2026-09-12T02:10:00Z',
          'status': 'FINAL',
          'withdrawn_at': null,
          'withdraw_reason': null,
        }),
      ];

      final filtered = patientOnlyReports(reports);

      expect(filtered, hasLength(1));
      expect(filtered.single.id, 1);
      expect(filtered.single.reportType, 'PATIENT');
    });

    test('download payload parses configured file URL', () {
      final download = PatientReportDownload.fromJson({
        'report': {
          'id': 1,
          'report_version': 11,
          'file_asset': 21,
          'withdrawn_by': null,
          'report_name': 'patient-report.pdf',
          'report_type': 'PATIENT',
          'created_at': '2026-09-12T02:00:00Z',
          'status': 'FINAL',
          'withdrawn_at': null,
          'withdraw_reason': null,
        },
        'file': {
          'file_id': 21,
          'storage_backend': 'RUSTFS',
          'bucket_name': 'reports',
          'object_key': 'patient/report-1.pdf',
          'mime_type': 'application/pdf',
          'checksum': 'sample-checksum',
          'size_bytes': 102400,
          'download_url': 'https://example.test/reports/patient/report-1.pdf',
          'download_integration_status': 'CONFIGURED',
        },
      });

      expect(download.report.isPatientReport, isTrue);
      expect(download.file.canDownload, isTrue);
      expect(download.file.mimeType, 'application/pdf');
    });
  });
}
