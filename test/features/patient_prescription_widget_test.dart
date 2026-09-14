import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/prescription/model/patient_prescription.dart';
import 'package:flutter_patient/features/prescription/repository/patient_prescription_repository.dart';
import 'package:flutter_patient/features/prescription/view/patient_prescription_list_screen.dart';

class _FakePrescriptionRepository extends PatientPrescriptionRepository {
  _FakePrescriptionRepository({this.empty = false}) : super(ApiClient());

  final bool empty;

  final medication = const PatientMedicationInfo(
    id: 7,
    name: '아스피린',
    ingredient: 'Aspirin',
    strength: '100mg',
  );

  late final item = PatientPrescriptionItem(
    id: 11,
    prescriptionId: 3,
    medicationId: 7,
    medication: medication,
    status: 'ACTIVE',
    doseValue: 100,
    doseUnit: 'mg',
    frequencyPerDay: 1,
    durationDays: 30,
    instructions: '식후 복용',
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2026, 9, 30),
  );

  late final canceledItem = PatientPrescriptionItem(
    id: 12,
    prescriptionId: 3,
    medicationId: 7,
    medication: const PatientMedicationInfo(id: 8, name: '취소된 약'),
    status: 'CANCELED',
  );

  late final prescription = PatientPrescription(
    id: 3,
    encounterId: 2,
    patientId: 5,
    prescribedById: 9,
    status: 'SIGNED',
    notes: '복약 지도 완료',
    prescribedAt: DateTime(2026, 9, 1),
    signedAt: DateTime(2026, 9, 1, 9, 30),
  );

  @override
  Future<List<PatientCurrentMedication>> getCurrentMedications() async {
    if (empty) return const [];

    return [
      PatientCurrentMedication(
        id: 21,
        medication: medication,
        prescriptionItem: item,
        status: 'ACTIVE',
        startedAt: DateTime(2026, 9, 1),
      ),
    ];
  }

  @override
  Future<List<PatientPrescription>> getPrescriptions() async {
    if (empty) return const [];
    return [prescription];
  }

  @override
  Future<PatientPrescriptionDetail> getPrescription(int prescriptionId) async {
    return PatientPrescriptionDetail(
      prescription: prescription,
      items: [item, canceledItem],
    );
  }
}

void main() {
  testWidgets('현재 복용약과 확정된 처방 이력을 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientPrescriptionListScreen(
          repository: _FakePrescriptionRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('현재 복용약'), findsOneWidget);
    expect(find.text('아스피린'), findsOneWidget);
    expect(find.text('하루 1회'), findsOneWidget);
    expect(find.text('처방 이력'), findsOneWidget);
    expect(find.text('복약 지도 완료'), findsOneWidget);
  });

  testWidgets('처방 상세에는 ACTIVE 약품만 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientPrescriptionListScreen(
          repository: _FakePrescriptionRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('prescription-3')));
    await tester.pumpAndSettle();

    expect(find.text('처방 상세'), findsOneWidget);
    expect(find.text('아스피린'), findsOneWidget);
    expect(find.text('식후 복용'), findsOneWidget);
    expect(find.text('취소된 약'), findsNothing);
  });

  testWidgets('복용약과 처방이 없으면 빈 상태를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatientPrescriptionListScreen(
          repository: _FakePrescriptionRepository(empty: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('현재 복용 중으로 등록된 약이 없어요.'), findsOneWidget);
    expect(find.text('확인할 수 있는 처방 이력이 없어요.'), findsOneWidget);
  });
}
