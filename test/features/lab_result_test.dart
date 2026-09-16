import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_patient/features/lab_result/model/lab_result.dart';
import 'package:flutter_patient/features/lab_result/repository/lab_result_repository.dart';
import 'package:flutter_patient/features/lab_result/view/lab_result_list_screen.dart';

class FakeLabResultRepository implements LabResultRepository {
  FakeLabResultRepository(this.results);

  final List<LabResult> results;

  @override
  Future<List<LabResult>> getLabResults() async => results;
}

class FakeFullLabResultRepository
    implements LabResultRepository, LabResultDetailRepository {
  FakeFullLabResultRepository({
    required this.results,
    required this.detail,
    required this.trend,
  });

  final List<LabResult> results;
  final LabResultDetail detail;
  final LabTrend trend;

  @override
  Future<List<LabResult>> getLabResults() async => results;

  @override
  Future<LabResultDetail> getLabResult(int resultId) async {
    return detail;
  }

  @override
  Future<LabTrend> getLabTrend(String code) async {
    return trend;
  }
}

void main() {
  test('LAB_PANEL is displayed as blood test', () {
    final result = LabResult(
      id: 1,
      resultType: 'LAB_PANEL',
      version: 1,
      collectedAt: DateTime.utc(2026, 9, 11),
      status: 'FINAL',
      summaryText: '',
    );

    expect(result.displayTitle, '혈액검사');
  });

  test('lab result parses patient API response', () {
    final result = LabResult.fromJson({
      'id': 101,
      'result_type': 'LAB_PANEL',
      'collected_at': '2026-09-11T09:30:00Z',
      'status': 'FINAL',
      'summary_text': '확정된 혈액검사 결과입니다.',
    });

    expect(result.id, 101);
    expect(result.resultType, 'LAB_PANEL');
    expect(result.status, 'FINAL');
    expect(result.summaryText, '확정된 혈액검사 결과입니다.');
    expect(result.displayTitle, '혈액검사');
    expect(result.version, isNull);
  });

  test('lab measurement parses value, range and abnormal flag', () {
    final measurement = LabMeasurement.fromJson({
      'id': 501,
      'measurement_id': 501,
      'clinical_variable_id': 10,
      'code': 'LDL',
      'name': 'LDL 콜레스테롤',
      'display_name': 'LDL 콜레스테롤',
      'value': 167.0,
      'value_numeric': 167.0,
      'value_text': null,
      'value_boolean': null,
      'unit': 'mg/dL',
      'reference_range_id': 3,
      'reference_min': 0.0,
      'reference_max': 129.0,
      'reference_text': '0 ~ 129',
      'abnormal_flag': 'HIGH',
      'validation_status': 'VALID',
      'measured_at': '2026-09-11T09:30:00Z',
    });

    expect(measurement.code, 'LDL');
    expect(measurement.name, 'LDL 콜레스테롤');
    expect(measurement.displayValue, '167');
    expect(measurement.displayUnit, 'mg/dL');
    expect(measurement.displayReference, '0 ~ 129');
    expect(measurement.normalizedFlag, 'HIGH');
    expect(measurement.measuredAt, isNotNull);
  });

  test('lab measurement safely handles null result values', () {
    final measurement = LabMeasurement.fromJson({
      'id': 502,
      'code': 'FBS',
      'name': '공복혈당',
      'value': null,
      'unit': null,
      'reference_min': null,
      'reference_max': null,
      'reference_text': null,
      'abnormal_flag': null,
      'measured_at': null,
    });

    expect(measurement.displayValue, '-');
    expect(measurement.displayUnit, '');
    expect(measurement.displayReference, '-');
    expect(measurement.normalizedFlag, '');
  });

  test('lab detail parses measurements', () {
    final detail = LabResultDetail.fromJson({
      'id': 101,
      'result_type': 'LAB_PANEL',
      'collected_at': '2026-09-11T09:30:00Z',
      'status': 'FINAL',
      'summary_text': '',
      'measurements': [
        {
          'id': 501,
          'code': 'LDL',
          'display_name': 'LDL 콜레스테롤',
          'value': 167.0,
          'unit': 'mg/dL',
          'reference_text': '0 ~ 129',
          'abnormal_flag': 'HIGH',
          'measured_at': '2026-09-11T09:30:00Z',
        },
        {
          'id': 502,
          'code': 'HDL',
          'display_name': 'HDL 콜레스테롤',
          'value': 35.0,
          'unit': 'mg/dL',
          'reference_text': '40 이상',
          'abnormal_flag': 'LOW',
          'measured_at': '2026-09-11T09:30:00Z',
        },
      ],
    });

    expect(detail.measurements, hasLength(2));
    expect(detail.measurements.first.normalizedFlag, 'HIGH');
    expect(detail.measurements.last.normalizedFlag, 'LOW');
  });

  test('lab trend parses chronological result points', () {
    final trend = LabTrend.fromJson({
      'code': 'LDL',
      'display_name': 'LDL 콜레스테롤',
      'unit': 'mg/dL',
      'results': [
        {
          'measured_at': '2026-03-01T09:00:00Z',
          'value': 167.0,
          'abnormal_flag': 'HIGH',
        },
        {
          'measured_at': '2026-05-30T09:00:00Z',
          'value': 125.0,
          'abnormal_flag': 'NORMAL',
        },
        {
          'measured_at': '2026-08-28T09:00:00Z',
          'value': 110.0,
          'abnormal_flag': 'NORMAL',
        },
      ],
    });

    expect(trend.code, 'LDL');
    expect(trend.displayName, 'LDL 콜레스테롤');
    expect(trend.unit, 'mg/dL');
    expect(trend.results, hasLength(3));
    expect(trend.results.first.value, 167.0);
    expect(trend.results.first.normalizedFlag, 'HIGH');
    expect(trend.results.last.value, 110.0);
    expect(
      trend.results.first.measuredAt.isBefore(trend.results.last.measuredAt),
      isTrue,
    );
  });

  test('lab trend safely handles empty result list', () {
    final trend = LabTrend.fromJson({
      'code': 'WBC',
      'display_name': null,
      'unit': null,
      'results': [],
    });

    expect(trend.code, 'WBC');
    expect(trend.displayName, isNull);
    expect(trend.results, isEmpty);
  });

  testWidgets('lab result opens legacy detail screen', (tester) async {
    final repository = FakeLabResultRepository([
      LabResult(
        id: 1,
        resultType: 'LAB_PANEL',
        version: 1,
        collectedAt: DateTime.parse('2026-09-11T00:10:00Z'),
        status: 'FINAL',
        summaryText: '혈액검사 결과가 확인되었습니다.',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: LabResultListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('혈액검사'), findsOneWidget);

    await tester.tap(find.text('혈액검사'));
    await tester.pumpAndSettle();

    expect(find.text('혈액검사 결과'), findsOneWidget);
    expect(find.text('이번 검사 한눈에'), findsOneWidget);
    expect(find.text('등록된 검사 수치가 없습니다.'), findsOneWidget);
    expect(find.text('확정 결과'), findsOneWidget);
  });

  testWidgets('lab detail displays measurement and abnormal badge', (
    tester,
  ) async {
    final result = LabResult(
      id: 101,
      resultType: 'LAB_PANEL',
      collectedAt: DateTime.parse('2026-09-11T09:30:00Z'),
      status: 'FINAL',
      summaryText: '혈액검사 결과입니다.',
    );

    final repository = FakeFullLabResultRepository(
      results: [result],
      detail: LabResultDetail(
        result: result,
        measurements: [
          LabMeasurement(
            id: 501,
            code: 'LDL',
            name: 'LDL 콜레스테롤',
            valueNumeric: 167,
            unit: 'mg/dL',
            referenceText: '0 ~ 129',
            abnormalFlag: 'HIGH',
            measuredAt: DateTime.parse('2026-09-11T09:30:00Z'),
          ),
        ],
      ),
      trend: LabTrend(
        code: 'LDL',
        displayName: 'LDL 콜레스테롤',
        unit: 'mg/dL',
        results: [
          LabTrendPoint(
            measuredAt: DateTime.parse('2026-03-01T09:00:00Z'),
            value: 180,
            abnormalFlag: 'HIGH',
          ),
          LabTrendPoint(
            measuredAt: DateTime.parse('2026-09-11T09:30:00Z'),
            value: 167,
            abnormalFlag: 'HIGH',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: LabResultListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('혈액검사'));
    await tester.pumpAndSettle();

    expect(find.text('LDL 콜레스테롤'), findsOneWidget);
    expect(find.text('167 mg/dL'), findsOneWidget);
    expect(find.text('0 ~ 129'), findsOneWidget);
    expect(find.text('높음 HIGH'), findsOneWidget);
    expect(find.text('추이 보기'), findsOneWidget);
  });

  testWidgets('lab trend screen opens from measurement', (tester) async {
    final result = LabResult(
      id: 101,
      resultType: 'LAB_PANEL',
      collectedAt: DateTime.parse('2026-09-11T09:30:00Z'),
      status: 'FINAL',
      summaryText: '',
    );

    final repository = FakeFullLabResultRepository(
      results: [result],
      detail: LabResultDetail(
        result: result,
        measurements: [
          const LabMeasurement(
            id: 501,
            code: 'LDL',
            name: 'LDL 콜레스테롤',
            valueNumeric: 167,
            unit: 'mg/dL',
            abnormalFlag: 'HIGH',
          ),
        ],
      ),
      trend: LabTrend(
        code: 'LDL',
        displayName: 'LDL 콜레스테롤',
        unit: 'mg/dL',
        results: [
          LabTrendPoint(
            measuredAt: DateTime.parse('2026-03-01T09:00:00Z'),
            value: 180,
            abnormalFlag: 'HIGH',
          ),
          LabTrendPoint(
            measuredAt: DateTime.parse('2026-09-11T09:30:00Z'),
            value: 167,
            abnormalFlag: 'HIGH',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: LabResultListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('혈액검사'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('추이 보기'));
    await tester.pumpAndSettle();

    expect(find.text('검사 수치 추이'), findsOneWidget);
    expect(find.text('수치 변화'), findsOneWidget);
    expect(find.text('검사 기록'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('180 mg/dL'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('180 mg/dL'), findsOneWidget);
    expect(find.text('167 mg/dL'), findsOneWidget);
  });

  testWidgets('lab result renders pending state without repository', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LabResultListScreen()));

    expect(find.text('검사결과 데이터 연동을 준비 중입니다.'), findsOneWidget);
  });

  testWidgets('lab result renders empty state', (tester) async {
    final repository = FakeLabResultRepository([]);

    await tester.pumpWidget(
      MaterialApp(home: LabResultListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('확인할 검사결과가 없어요.'), findsOneWidget);
  });
}
