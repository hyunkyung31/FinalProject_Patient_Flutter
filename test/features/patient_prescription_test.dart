import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/features/prescription/model/patient_prescription.dart';

void main() {
  const medication = {
    'id': 7,
    'code': 'MED-007',
    'name': '아스피린',
    'ingredient': 'Aspirin',
    'default_unit': 'mg',
    'manufacturer': '테스트제약',
    'dosage_form': '정제',
    'strength': '100mg',
  };

  Map<String, dynamic> item({String status = 'ACTIVE'}) {
    return {
      'id': status == 'ACTIVE' ? 11 : 12,
      'prescription': 3,
      'medication': 7,
      'medication_detail': medication,
      'status': status,
      'note': null,
      'dose_value': '100.000',
      'dose_unit': 'mg',
      'frequency_per_day': 1,
      'duration_days': 30,
      'route': 'PO',
      'instructions': '식후 복용',
      'start_date': '2026-09-01',
      'end_date': '2026-09-30',
    };
  }

  test('처방 항목에서 약품과 복용 정보를 파싱한다', () {
    final result = PatientPrescriptionItem.fromJson(item());

    expect(result.medication.name, '아스피린');
    expect(result.medication.ingredient, 'Aspirin');
    expect(result.doseValue, 100);
    expect(result.doseUnit, 'mg');
    expect(result.frequencyPerDay, 1);
    expect(result.durationDays, 30);
    expect(result.instructions, '식후 복용');
    expect(result.isActive, isTrue);
  });

  test('현재 복용약 응답을 파싱한다', () {
    final result = PatientCurrentMedication.fromJson({
      'id': 21,
      'patient': 5,
      'medication': 7,
      'medication_detail': medication,
      'prescription_item': 11,
      'prescription_item_detail': item(),
      'status': 'ACTIVE',
      'started_at': '2026-09-01T09:00:00+09:00',
      'ended_at': null,
    });

    expect(result.medication.name, '아스피린');
    expect(result.prescriptionItem.frequencyPerDay, 1);
    expect(result.isActive, isTrue);
  });

  test('SIGNED 처방을 환자 공개 처방으로 판별한다', () {
    final result = PatientPrescription.fromJson({
      'id': 3,
      'encounter': 2,
      'patient': 5,
      'prescribed_by': 9,
      'status': 'SIGNED',
      'notes': '복약 지도 완료',
      'prescribed_at': '2026-09-01T09:00:00+09:00',
      'signed_at': '2026-09-01T09:30:00+09:00',
      'canceled_at': null,
      'cancel_reason': null,
    });

    expect(result.isSigned, isTrue);
  });

  test('처방 상세에서는 ACTIVE 항목만 별도로 조회할 수 있다', () {
    final detail = PatientPrescriptionDetail.fromJson({
      'prescription': {
        'id': 3,
        'encounter': 2,
        'patient': 5,
        'prescribed_by': 9,
        'status': 'SIGNED',
        'notes': null,
        'prescribed_at': '2026-09-01T09:00:00+09:00',
        'signed_at': '2026-09-01T09:30:00+09:00',
        'canceled_at': null,
        'cancel_reason': null,
      },
      'items': [item(), item(status: 'CANCELED')],
    });

    expect(detail.items, hasLength(2));
    expect(detail.activeItems, hasLength(1));
    expect(detail.activeItems.first.status, 'ACTIVE');
  });
}
