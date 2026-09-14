import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/medical_history/model/medical_timeline.dart';
import 'package:flutter_patient/features/medical_history/repository/medical_history_repository.dart';
import 'package:flutter_patient/features/medical_history/view/medical_history_screen.dart';

class FakeMedicalHistoryRepository extends MedicalHistoryRepository {
  FakeMedicalHistoryRepository({this.timeline, this.error})
    : super(ApiClient());

  final MedicalTimeline? timeline;
  final Object? error;

  @override
  Future<MedicalTimeline> getTimeline() async {
    if (error != null) throw error!;
    return timeline!;
  }
}

void main() {
  test('timeline response is parsed correctly', () {
    final timeline = MedicalTimeline.fromJson({
      'patient_id': 15,
      'results': [
        {
          'event_type': 'ENCOUNTER',
          'reference_id': 101,
          'occurred_at': '2026-09-13T01:19:04.081Z',
          'title': '순환기내과 진료',
          'status': 'COMPLETED',
          'summary': '외래 진료 완료',
          'data': '',
        },
      ],
    });

    expect(timeline.patientId, 15);
    expect(timeline.results, hasLength(1));

    final item = timeline.results.single;

    expect(item.eventType, 'ENCOUNTER');
    expect(item.referenceId, 101);
    expect(item.title, '순환기내과 진료');
    expect(item.status, 'COMPLETED');
    expect(item.occurredAtKst.hour, 10);
  });

  testWidgets('medical history renders timeline item', (tester) async {
    final repository = FakeMedicalHistoryRepository(
      timeline: MedicalTimeline(
        patientId: 15,
        results: [
          MedicalTimelineItem(
            eventType: 'ENCOUNTER',
            referenceId: 101,
            occurredAt: DateTime.parse('2026-09-13T01:19:04.081Z'),
            title: '순환기내과 진료',
            status: 'COMPLETED',
            summary: '외래 진료 완료',
            data: '',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: MedicalHistoryScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('진료 · 검사이력'), findsOneWidget);
    expect(find.text('순환기내과 진료'), findsOneWidget);
    expect(find.text('외래 진료 완료'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
  });

  testWidgets('medical history renders empty state', (tester) async {
    final repository = FakeMedicalHistoryRepository(
      timeline: const MedicalTimeline(patientId: 15, results: []),
    );

    await tester.pumpWidget(
      MaterialApp(home: MedicalHistoryScreen(repository: repository)),
    );

    await tester.pumpAndSettle();

    expect(find.text('진료·검사이력이 없어요.'), findsOneWidget);
  });
}
