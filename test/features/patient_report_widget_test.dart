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

    expect(find.text('최종 진료 보고서'), findsOneWidget);
    expect(find.text('검사와 AI 분석 결과를 종합한 최종 요약입니다.'), findsOneWidget);
    expect(find.text('공개 완료'), findsOneWidget);

    await tester.tap(find.text('최종 진료 보고서'));
    await tester.pumpAndSettle();

    expect(find.text('결과 요약'), findsOneWidget);
    expect(find.text('의료진 결론'), findsOneWidget);
    expect(find.text('환자용 보고서'), findsOneWidget);
    expect(find.text('patient-report.pdf'), findsOneWidget);
    expect(find.text('보고서 보기'), findsOneWidget);
    expect(find.text('현재 상태를 의료진과 함께 지속적으로 확인해 주세요.'), findsOneWidget);
  });

  testWidgets('report button checks download API and shows pending message', (
    tester,
  ) async {
    final repository = _FakePatientReportRepository(
      results: [releasedResult],
      detail: detail,
      download: download,
    );

    await tester.pumpWidget(
      MaterialApp(home: PatientReportListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('최종 진료 보고서'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('보고서 보기'));
    await tester.pumpAndSettle();

    expect(find.text('보고서 파일 보기 기능은 연동 준비 중입니다.'), findsOneWidget);
  });

  testWidgets('empty released result shows empty state', (tester) async {
    final repository = _FakePatientReportRepository();

    await tester.pumpWidget(
      MaterialApp(home: PatientReportListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('공개된 최종 보고서가 없습니다.'), findsOneWidget);
    expect(find.text('의료진 검토와 승인 후 보고서가 공개됩니다.'), findsOneWidget);
  });
}
