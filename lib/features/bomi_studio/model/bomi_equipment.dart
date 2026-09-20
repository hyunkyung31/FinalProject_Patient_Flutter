class BomiEquipment {
  const BomiEquipment({
    required this.id,
    required this.patientAccount,
    required this.createdAt,
    required this.updatedAt,
    this.outfitRewardCode,
    this.accessoryRewardCode,
    this.backgroundRewardCode,
  });

  final int id;
  final int patientAccount;
  final String? outfitRewardCode;
  final String? accessoryRewardCode;
  final String? backgroundRewardCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BomiEquipment.fromJson(Map<String, dynamic> json) {
    return BomiEquipment(
      id: _requiredInt(json['id'], 'id'),
      patientAccount: _requiredInt(json['patient_account'], 'patient_account'),
      outfitRewardCode: _nullableString(json['outfit_reward_code']),
      accessoryRewardCode: _nullableString(json['accessory_reward_code']),
      backgroundRewardCode: _nullableString(json['background_reward_code']),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
    );
  }
}

int _requiredInt(Object? value, String fieldName) {
  if (value is int) return value;

  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }
  return parsed;
}

String? _nullableString(Object? value) {
  if (value == null) return null;

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime _requiredDateTime(Object? value, String fieldName) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');

  if (parsed == null) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }

  return parsed;
}
