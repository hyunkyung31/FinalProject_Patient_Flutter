import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/patient_report/model/patient_report.dart';
import 'package:flutter_patient/features/patient_report/repository/patient_report_repository.dart';
import 'package:flutter_patient/features/patient_report/view/patient_report_list_screen.dart';

class _FakePatientReportRepository extends PatientReportRepository {
  _FakePatientReportRepository({
    this.results = const [],
    this.detail,
    this.download,
  }) : super(ApiClient());

  final List<PatientReleasedResult> results;
  final PatientReleasedResultDetail? detail;
  final PatientReportDownload? download;

  @override
  Future<List<PatientReleasedResult>> getResults() async {
    return results;
  }

  @override
  Future<PatientReleasedResultDetail> getResult(int resultId) async {
    final value = detail;

    if (value == null) {
      throw StateError('상세 결과가 없습니다.');
    }

    return value;
  }

  @override
  Future<PatientReportDownload> getDownload(int reportId) async {
    final value = download;

    if (value == null) {
      throw StateError('다운로드 정보가 없습니다.');
    }

    return value;
  }
}

void main() {
  final medicalResult = PatientMedicalResult(
    id: 10,
    encounterId: 20,
    patientId: 30,
    finalAssessmentId: 40,
    summary: '검사와 AI 분석 결과를 종합한 최종 요약입니다.',
    conclusion: '현재 상태를 의료진과 함께 지속적으로 확인해 주세요.',
    status: 'RELEASED',
    createdAt: DateTime(2026, 9, 10),
    updatedAt: DateTime(2026, 9, 12),
  );

  final report = PatientReport(
    id: 100,
    reportVersionId: 200,
    fileAssetId: 300,
    reportName: 'patient-report.pdf',
    reportType: 'PATIENT',
    createdAt: DateTime(2026, 9, 12),
    status: 'FINAL',
  );

  final releasedResult = PatientReleasedResult(
    medicalResult: medicalResult,
    releasedAt: DateTime(2026, 9, 12),
    releaseIds: const [501],
  );

  final detail = PatientReleasedResultDetail(
    medicalResult: medicalResult,
    reports: [report],
  );

  final download = PatientReportDownload(
    report: report,
    file: const PatientReportFile(
      fileId: 300,
      storageBackend: 'RUSTFS',
      bucketName: 'reports',
      objectKey: 'patient/patient-report.pdf',
      mimeType: 'application/pdf',
      checksum: 'sample-checksum',
      sizeBytes: 102400,
      downloadUrl: 'https://example.test/patient-report.pdf',
      integrationStatus: 'CONFIGURED',
    ),
  );

  testWidgets('released result opens patient report detail', (tester) async {
    final repository = _FakePatientReportRepository(
      results: [releasedResult],
      detail: detail,
      download: download,
    );

    await tester.pumpWidget(
      MaterialApp(home: PatientReportListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('심혈관 통합 리포트'), findsWidgets);
    expect(find.text('검사와 AI 분석 결과를 종합한 최종 요약입니다.'), findsOneWidget);
    expect(find.text('공개 완료'), findsOneWidget);

    final reportCardTitle = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('심혈관 통합 리포트'),
    );

    expect(reportCardTitle, findsOneWidget);

    await tester.tap(reportCardTitle);
    await tester.pumpAndSettle();

    expect(find.text('검사 결과를 한눈에 확인하세요'), findsOneWidget);
    expect(find.text('의료진 검토 완료'), findsOneWidget);
    expect(find.text('한눈에 보는 요약'), findsOneWidget);
    expect(find.text('의료진 최종 소견'), findsOneWidget);
    expect(find.text('현재 상태를 의료진과 함께 지속적으로 확인해 주세요.'), findsOneWidget);
  });

  testWidgets('integrated report is shown without PDF action', (tester) async {
    final repository = _FakePatientReportRepository(
      results: [releasedResult],
      detail: detail,
      download: download,
    );

    await tester.pumpWidget(
      MaterialApp(home: PatientReportListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    final reportCardTitle = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('심혈관 통합 리포트'),
    );

    expect(reportCardTitle, findsOneWidget);

    await tester.tap(reportCardTitle);
    await tester.pumpAndSettle();

    expect(find.text('한눈에 보는 요약'), findsOneWidget);
    expect(find.text('의료진 최종 소견'), findsOneWidget);
    expect(find.text('보고서 보기'), findsNothing);
    expect(find.text('patient-report.pdf'), findsNothing);
  });

  testWidgets('empty released result shows empty state', (tester) async {
    final repository = _FakePatientReportRepository();

    await tester.pumpWidget(
      MaterialApp(home: PatientReportListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('공개된 심혈관 리포트가 없습니다.'), findsOneWidget);
    expect(find.text('의료진 검토와 승인 후 통합 리포트가 공개됩니다.'), findsOneWidget);
  });

  testWidgets('integrated report renders same encounter clinical sections', (
    tester,
  ) async {
    final integratedDetail = PatientReleasedResultDetail.fromJson({
      'medical_result': {
        'id': 10,
        'encounter': 20,
        'patient': 30,
        'final_assessment': 40,
        'summary': '검사와 AI 분석 결과를 종합한 최종 요약입니다.',
        'conclusion': '의료진의 최종 판단입니다.',
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
              'abnormal_flag': 'NORMAL',
              'validation_status': 'VALID',
              'measured_at': '2026-09-11T01:10:00Z',
            },
          ],
        },
      ],
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
          'detections': [],
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

    final repository = _FakePatientReportRepository(
      results: [releasedResult],
      detail: integratedDetail,
    );

    await tester.pumpWidget(
      MaterialApp(home: PatientReportListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    final reportCardTitle = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('심혈관 통합 리포트'),
    );

    await tester.tap(reportCardTitle);
    await tester.pumpAndSettle();

    expect(find.text('혈액검사'), findsOneWidget);
    expect(find.text('LDL 콜레스테롤'), findsOneWidget);
    expect(find.text('121 mg/dL'), findsOneWidget);
    expect(find.text('참고범위 0 ~ 129 mg/dL · 정상 범위'), findsOneWidget);

    expect(find.text('혈관조영술'), findsOneWidget);
    expect(find.text('혈관조영술 AI 분석 결과입니다.'), findsOneWidget);
    expect(find.text('LAD · mid LAD'), findsOneWidget);
    expect(find.text('62% 협착'), findsOneWidget);
    expect(find.text('중증도 SIGNIFICANT'), findsOneWidget);

    // 아래쪽 검사 섹션까지 실제 사용자처럼 스크롤합니다.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('혈관 CT'), findsOneWidget);
    expect(find.text('혈관 CT AI 분석 결과입니다.'), findsOneWidget);
    expect(find.text('CAC 총점'), findsOneWidget);
    expect(find.text('215'), findsOneWidget);
    expect(find.text('위험 분류 MODERATE'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('AI가 쉽게 설명해 드려요'), findsOneWidget);
    expect(find.text('관상동맥 일부에서 협착 소견이 확인되었습니다.'), findsOneWidget);
    expect(find.text('관상동맥 석회화 점수가 확인되었습니다.'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('의료진 최종 소견'), findsOneWidget);
    expect(find.text('의료진의 최종 판단입니다.'), findsOneWidget);
  });

  testWidgets(
    'integrated report hides unavailable CCTA and non-patient explanation',
    (tester) async {
      final partialDetail = PatientReleasedResultDetail.fromJson({
        'medical_result': {
          'id': 10,
          'encounter': 20,
          'patient': 30,
          'final_assessment': 40,
          'summary': '혈관조영술 결과 요약입니다.',
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
            'detections': [],
            'lesions': [],
            'cac_scores': [],
            'explanations': [
              {
                'explanation_type': 'CLINICAL',
                'summary_text': '의료진용 내부 설명입니다.',
                'generated_at': '2026-09-11T02:11:00Z',
              },
            ],
          },
        ],
      });

      final repository = _FakePatientReportRepository(
        results: [releasedResult],
        detail: partialDetail,
      );

      await tester.pumpWidget(
        MaterialApp(home: PatientReportListScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      final reportCardTitle = find.descendant(
        of: find.byType(InkWell),
        matching: find.text('심혈관 통합 리포트'),
      );

      await tester.tap(reportCardTitle);
      await tester.pumpAndSettle();

      expect(find.text('혈관조영술'), findsOneWidget);

      // 해당 Encounter에 없는 검사 결과는 빈 카드로 표시하지 않습니다.
      expect(find.text('혈액검사'), findsNothing);
      expect(find.text('혈관 CT'), findsNothing);

      // 환자용(PATIENT)이 아닌 AI 설명도 환자 리포트에 노출하지 않습니다.
      expect(find.text('AI가 쉽게 설명해 드려요'), findsNothing);
      expect(find.text('의료진용 내부 설명입니다.'), findsNothing);

      expect(find.text('의료진 최종 소견'), findsOneWidget);
    },
  );
}
