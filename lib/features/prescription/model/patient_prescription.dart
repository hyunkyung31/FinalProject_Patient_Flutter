class PatientMedicationInfo {
  const PatientMedicationInfo({
    required this.id,
    required this.name,
    this.code,
    this.ingredient,
    this.defaultUnit,
    this.manufacturer,
    this.dosageForm,
    this.strength,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String? code;
  final String? ingredient;
  final String? defaultUnit;
  final String? manufacturer;
  final String? dosageForm;
  final String? strength;
  final String? imageUrl;

  factory PatientMedicationInfo.fromJson(Map<String, dynamic> json) {
    return PatientMedicationInfo(
      id: _asInt(json['id']),
      name: _asString(json['name']) ?? '',
      code: _asString(json['code']),
      ingredient: _asString(json['ingredient']),
      defaultUnit: _asString(json['default_unit']),
      manufacturer: _asString(json['manufacturer']),
      dosageForm: _asString(json['dosage_form']),
      strength: _asString(json['strength']),
      imageUrl: _asString(json['image_url']),
    );
  }
}

class PatientPrescriptionItem {
  const PatientPrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.medicationId,
    required this.medication,
    required this.status,
    this.note,
    this.doseValue,
    this.doseUnit,
    this.frequencyPerDay,
    this.durationDays,
    this.route,
    this.instructions,
    this.startDate,
    this.endDate,
  });

  final int id;
  final int prescriptionId;
  final int medicationId;
  final PatientMedicationInfo medication;
  final String status;
  final String? note;
  final double? doseValue;
  final String? doseUnit;
  final int? frequencyPerDay;
  final int? durationDays;
  final String? route;
  final String? instructions;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory PatientPrescriptionItem.fromJson(Map<String, dynamic> json) {
    final medicationJson = json['medication_detail'];

    if (medicationJson is! Map) {
      throw const FormatException('약품 상세 정보가 없습니다.');
    }

    return PatientPrescriptionItem(
      id: _asInt(json['id']),
      prescriptionId: _asInt(json['prescription']),
      medicationId: _asInt(json['medication']),
      medication: PatientMedicationInfo.fromJson(
        Map<String, dynamic>.from(medicationJson),
      ),
      status: _asString(json['status']) ?? '',
      note: _asString(json['note']),
      doseValue: _asDouble(json['dose_value']),
      doseUnit: _asString(json['dose_unit']),
      frequencyPerDay: _asNullableInt(json['frequency_per_day']),
      durationDays: _asNullableInt(json['duration_days']),
      route: _asString(json['route']),
      instructions: _asString(json['instructions']),
      startDate: _asDate(json['start_date']),
      endDate: _asDate(json['end_date']),
    );
  }
}

class PatientCurrentMedication {
  const PatientCurrentMedication({
    required this.id,
    required this.medication,
    required this.prescriptionItem,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });

  final int id;
  final PatientMedicationInfo medication;
  final PatientPrescriptionItem prescriptionItem;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory PatientCurrentMedication.fromJson(Map<String, dynamic> json) {
    final medicationJson = json['medication_detail'];
    final itemJson = json['prescription_item_detail'];

    if (medicationJson is! Map || itemJson is! Map) {
      throw const FormatException('현재 복용약 상세 정보가 없습니다.');
    }

    final startedAt = _asDate(json['started_at']);
    if (startedAt == null) {
      throw const FormatException('복용 시작일이 없습니다.');
    }

    return PatientCurrentMedication(
      id: _asInt(json['id']),
      medication: PatientMedicationInfo.fromJson(
        Map<String, dynamic>.from(medicationJson),
      ),
      prescriptionItem: PatientPrescriptionItem.fromJson(
        Map<String, dynamic>.from(itemJson),
      ),
      status: _asString(json['status']) ?? '',
      startedAt: startedAt,
      endedAt: _asDate(json['ended_at']),
    );
  }
}

class PatientPrescription {
  const PatientPrescription({
    required this.id,
    required this.encounterId,
    required this.patientId,
    required this.prescribedById,
    required this.status,
    required this.prescribedAt,
    this.notes,
    this.signedAt,
    this.canceledAt,
    this.cancelReason,
  });

  final int id;
  final int encounterId;
  final int patientId;
  final int prescribedById;
  final String status;
  final String? notes;
  final DateTime prescribedAt;
  final DateTime? signedAt;
  final DateTime? canceledAt;
  final String? cancelReason;

  bool get isSigned => status.toUpperCase() == 'SIGNED';

  factory PatientPrescription.fromJson(Map<String, dynamic> json) {
    final prescribedAt = _asDate(json['prescribed_at']);

    if (prescribedAt == null) {
      throw const FormatException('처방 일자가 없습니다.');
    }

    return PatientPrescription(
      id: _asInt(json['id']),
      encounterId: _asInt(json['encounter']),
      patientId: _asInt(json['patient']),
      prescribedById: _asInt(json['prescribed_by']),
      status: _asString(json['status']) ?? '',
      notes: _asString(json['notes']),
      prescribedAt: prescribedAt,
      signedAt: _asDate(json['signed_at']),
      canceledAt: _asDate(json['canceled_at']),
      cancelReason: _asString(json['cancel_reason']),
    );
  }
}

class PatientPrescriptionDetail {
  const PatientPrescriptionDetail({
    required this.prescription,
    required this.items,
  });

  final PatientPrescription prescription;
  final List<PatientPrescriptionItem> items;

  List<PatientPrescriptionItem> get activeItems =>
      items.where((item) => item.isActive).toList(growable: false);

  factory PatientPrescriptionDetail.fromJson(Map<String, dynamic> json) {
    final prescriptionJson = json['prescription'];
    final itemJson = json['items'];

    if (prescriptionJson is! Map || itemJson is! List) {
      throw const FormatException('처방 상세 응답 형식이 올바르지 않습니다.');
    }

    return PatientPrescriptionDetail(
      prescription: PatientPrescription.fromJson(
        Map<String, dynamic>.from(prescriptionJson),
      ),
      items: itemJson
          .map(
            (item) => PatientPrescriptionItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

String? _asString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _asInt(Object? value) {
  final result = _asNullableInt(value);
  if (result == null) {
    throw const FormatException('필수 숫자 값이 없습니다.');
  }
  return result;
}

int? _asNullableInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

DateTime? _asDate(Object? value) {
  final text = _asString(value);
  return text == null ? null : DateTime.tryParse(text);
}
