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

    test('integrated detail parses lab results', () {
      final detail = PatientReleasedResultDetail.fromJson({
        'medical_result': {
          'id': 10,
          'encounter': 20,
          'patient': 30,
          'final_assessment': 40,
          'summary': '통합 검사 결과입니다.',
          'conclusion': '의료진 최종 소견입니다.',
          'status': 'RELEASED',
          'created_at': '2026-09-10T01:00:00Z',
          'updated_at': '2026-09-12T01:00:00Z',
        },
        'reports': [],
        'lab_results': [
          {
            'id': 71,
            'examination_id': 401,
            'performed_at': '2026-09-11T01:00:00Z',
            'result_type': 'LAB_PANEL',
            'collected_at': '2026-09-11T01:10:00Z',
            'status': 'FINAL',
            'summary_text': '혈액검사 결과입니다.',
            'measurements': [
              {
                'id': 701,
                'measurement_id': 701,
                'clinical_variable_id': 31,
                'code': 'LDL',
                'name': 'LDL Cholesterol',
                'display_name': 'LDL 콜레스테롤',
                'value': 121.0,
                'value_numeric': 121.0,
                'unit': 'mg/dL',
                'reference_range_id': 44,
                'reference_min': 0,
                'reference_max': 129,
                'reference_text': null,
                'abnormal_flag': 'NORMAL',
                'validation_status': 'VALID',
                'measured_at': '2026-09-11T01:10:00Z',
              },
            ],
          },
        ],
        'ai_results': [],
      });

      expect(detail.labResults, hasLength(1));
      expect(detail.labResults.single.result.resultType, 'LAB_PANEL');
      expect(detail.labResults.single.measurements, hasLength(1));

      final measurement = detail.labResults.single.measurements.single;

      expect(measurement.code, 'LDL');
      expect(measurement.name, 'LDL 콜레스테롤');
      expect(measurement.displayValue, '121');
      expect(measurement.displayUnit, 'mg/dL');
      expect(measurement.displayReference, '0 ~ 129');
      expect(measurement.normalizedFlag, 'NORMAL');

      expect(detail.aiResults, isEmpty);
    });

    test(
      'integrated detail keeps backward compatibility without new fields',
      () {
        final detail = PatientReleasedResultDetail.fromJson({
          'medical_result': {
            'id': 10,
            'encounter': 20,
            'patient': 30,
            'final_assessment': null,
            'summary': null,
            'conclusion': null,
            'status': 'RELEASED',
            'created_at': '2026-09-10T01:00:00Z',
            'updated_at': '2026-09-12T01:00:00Z',
          },
          'reports': [],
        });

        expect(detail.labResults, isEmpty);
        expect(detail.aiResults, isEmpty);
      },
    );
    test('integrated detail parses XCA and CCTA AI results', () {
      final detail = PatientReleasedResultDetail.fromJson({
        'medical_result': {
          'id': 10,
          'encounter': 20,
          'patient': 30,
          'final_assessment': 40,
          'summary': '통합 검사 결과입니다.',
          'conclusion': '의료진 최종 소견입니다.',
          'status': 'RELEASED',
          'created_at': '2026-09-10T01:00:00Z',
          'updated_at': '2026-09-12T01:00:00Z',
        },
        'reports': [],
        'lab_results': [],
        'ai_results': [
          {
            'id': 81,
            'analysis_id': 501,
            'analysis_type': 'ANGIO_2D',
            'examination_id': 401,
            'performed_at': '2026-09-11T02:00:00Z',
            'result_type': 'DETECTION',
            'summary_text': '혈관조영술 AI 분석 결과입니다.',
            'confidence': 0.92,
            'generated_at': '2026-09-11T02:10:00Z',
            'status': 'VALID',
            'detections': [
              {
                'finding_type': 'STENOSIS',
                'artery_segment': 'LAD',
                'confidence': 0.91,
                'severity': 'MODERATE',
              },
            ],
            'lesions': [
              {
                'artery_name': 'LAD',
                'segment_name': 'mid LAD',
                'stenosis_percent': 62.0,
                'lesion_volume_mm3': 14.2,
                'severity_grade': 'SIGNIFICANT',
              },
            ],
            'cac_scores': [],
            'explanations': [
              {
                'explanation_type': 'PATIENT',
                'summary_text': '관상동맥 일부에서 협착 소견이 확인되었습니다.',
                'generated_at': '2026-09-11T02:11:00Z',
              },
            ],
          },
          {
            'id': 82,
            'analysis_id': 502,
            'analysis_type': 'CCTA',
            'examination_id': 402,
            'performed_at': '2026-09-11T03:00:00Z',
            'result_type': 'SEGMENTATION',
            'summary_text': '혈관 CT AI 분석 결과입니다.',
            'confidence': 0.88,
            'generated_at': '2026-09-11T03:10:00Z',
            'status': 'VALID',
            'detections': [],
            'lesions': [],
            'cac_scores': [
              {
                'score_value': 215.0,
                'lad_score': 120.0,
                'lcx_score': 45.0,
                'rca_score': 50.0,
                'percentile': 78.0,
                'risk_category': 'MODERATE',
                'calculated_at': '2026-09-11T03:11:00Z',
              },
            ],
            'explanations': [
              {
                'explanation_type': 'PATIENT',
                'summary_text': '관상동맥 석회화 점수가 확인되었습니다.',
                'generated_at': '2026-09-11T03:12:00Z',
              },
            ],
          },
        ],
      });

      expect(detail.aiResults, hasLength(2));

      final xca = detail.aiResults.firstWhere(
        (result) => result.analysisType == 'ANGIO_2D',
      );

      expect(xca.resultType, 'DETECTION');
      expect(xca.summaryText, '혈관조영술 AI 분석 결과입니다.');
      expect(xca.detections, hasLength(1));
      expect(xca.detections.single.arterySegment, 'LAD');
      expect(xca.lesions, hasLength(1));
      expect(xca.lesions.single.arteryName, 'LAD');
      expect(xca.lesions.single.stenosisPercent, 62.0);
      expect(xca.explanations, hasLength(1));

      final ccta = detail.aiResults.firstWhere(
        (result) => result.analysisType == 'CCTA',
      );

      expect(ccta.resultType, 'SEGMENTATION');
      expect(ccta.summaryText, '혈관 CT AI 분석 결과입니다.');
      expect(ccta.cacScores, hasLength(1));
      expect(ccta.cacScores.single.scoreValue, 215.0);
      expect(ccta.cacScores.single.ladScore, 120.0);
      expect(ccta.cacScores.single.lcxScore, 45.0);
      expect(ccta.cacScores.single.rcaScore, 50.0);
      expect(ccta.cacScores.single.riskCategory, 'MODERATE');
      expect(ccta.explanations.single.summaryText, '관상동맥 석회화 점수가 확인되었습니다.');

      expect(detail.labResults, isEmpty);
    });
  });
}
