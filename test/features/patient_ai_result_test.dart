import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/ai_result/model/patient_ai_result.dart';
import 'package:flutter_patient/features/ai_result/repository/patient_ai_result_repository.dart';
import 'package:flutter_patient/features/ai_result/view/patient_ai_result_list_screen.dart';

/// 화면 테스트용 AI 결과 Repository
class FakePatientAIResultRepository extends PatientAIResultRepository {
  FakePatientAIResultRepository({required this.results}) : super(ApiClient());

  final List<PatientAIResult> results;

  @override
  Future<List<PatientAIResult>> getResults({
    DateTime? date,
    String? resultType,
  }) async {
    return results;
  }

  @override
  Future<PatientAIResult> getResult(int resultId) async {
    return results.firstWhere((result) => result.id == resultId);
  }
}

/// 테스트에서 사용하는 공개 AI 결과 생성
PatientAIResult sampleResult({
  int id = 10,
  String analysisType = '',
  String resultType = 'DETECTION',
  String summaryText = 'AI 분석 결과가 확인되었습니다.',
}) {
  return PatientAIResult(
    id: id,
    analysisId: 20,
    analysisType: analysisType,
    resultType: resultType,
    summaryText: summaryText,
    confidence: 0.91,
    generatedAt: DateTime.utc(2026, 9, 13),
    status: 'VALID',
    detections: const [],
    lesions: const [],
    cacScores: const [],
    explanations: [
      PatientAIExplanation(
        explanationType: 'SHAP',
        summaryText: '검사 결과를 쉽게 이해할 수 있도록 설명한 내용입니다.',
        generatedAt: DateTime.utc(2026, 9, 13),
      ),
    ],
  );
}

void main() {
  test('patient AI result parses XAI explanation', () {
    final result = PatientAIResult.fromJson({
      'id': 10,
      'analysis_id': 20,
      'analysis_type': 'ANGIO_2D',
      'result_type': 'DETECTION',
      'summary_text': '결과 요약',
      'confidence': '0.910000',
      'generated_at': '2026-09-13T00:00:00Z',
      'status': 'VALID',
      'detections': [],
      'lesions': [],
      'cac_scores': [],
      'explanations': [
        {
          'explanation_type': 'SHAP',
          'summary_text': '쉬운 AI 설명',
          'generated_at': '2026-09-13T00:00:00Z',
        },
      ],
    });

    expect(result.id, 10);
    expect(result.analysisType, 'ANGIO_2D');
    expect(result.confidence, 0.91);
    expect(result.explanations.single.summaryText, '쉬운 AI 설명');
  });

  test('patient AI result parses CCTA analysis type', () {
    final result = PatientAIResult.fromJson({
      'id': 11,
      'analysis_id': 21,
      'analysis_type': 'CCTA',
      'result_type': 'SEGMENTATION',
      'summary_text': 'CCTA 석회화 분할 완료',
      'confidence': null,
      'generated_at': '2026-09-13T00:00:00Z',
      'status': 'VALID',
      'detections': [],
      'lesions': [],
      'cac_scores': [],
      'explanations': [],
    });

    expect(result.analysisType, 'CCTA');
    expect(result.resultType, 'SEGMENTATION');
  });

  test(
    'patient AI result keeps compatibility when analysis type is missing',
    () {
      final result = PatientAIResult.fromJson({
        'id': 12,
        'analysis_id': 22,
        'result_type': 'DETECTION',
        'summary_text': '기존 API 결과',
        'confidence': null,
        'generated_at': '2026-09-13T00:00:00Z',
        'status': 'VALID',
        'detections': [],
        'lesions': [],
        'cac_scores': [],
        'explanations': [],
      });

      expect(result.analysisType, isEmpty);
    },
  );

  testWidgets('AI result opens detail and shows XAI explanation', (
    tester,
  ) async {
    final repository = FakePatientAIResultRepository(results: [sampleResult()]);

    await tester.pumpWidget(
      MaterialApp(home: PatientAIResultListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('AI 분석 결과'), findsWidgets);
    expect(find.text('공개 완료'), findsOneWidget);

    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    expect(find.text('결과 요약'), findsOneWidget);
    expect(find.text('AI가 쉽게 설명해 드려요'), findsOneWidget);
    expect(find.text('검사 결과를 쉽게 이해할 수 있도록 설명한 내용입니다.'), findsOneWidget);
  });

  testWidgets('AI result filters results by analysis type', (tester) async {
    final repository = FakePatientAIResultRepository(
      results: [
        sampleResult(id: 10, analysisType: 'ANGIO_2D', summaryText: '혈관조영술 결과'),
        sampleResult(
          id: 11,
          analysisType: 'CCTA',
          resultType: 'SEGMENTATION',
          summaryText: '혈관 CT 결과',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PatientAIResultListScreen(
          repository: repository,
          analysisType: 'ANGIO_2D',
          title: '혈관조영술',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('혈관조영술'), findsOneWidget);
    expect(find.text('혈관조영술 결과'), findsOneWidget);
    expect(find.text('혈관 CT 결과'), findsNothing);
  });

  testWidgets('AI result renders empty state', (tester) async {
    final repository = FakePatientAIResultRepository(results: []);

    await tester.pumpWidget(
      MaterialApp(home: PatientAIResultListScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('공개된 AI 분석 결과가 없어요.'), findsOneWidget);
  });
}
