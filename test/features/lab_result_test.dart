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

  testWidgets('lab result opens detail screen', (tester) async {
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
    expect(find.text('결과 요약'), findsOneWidget);
    expect(find.text('혈액검사 결과가 확인되었습니다.'), findsOneWidget);
    expect(find.text('최종 확인'), findsOneWidget);
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
