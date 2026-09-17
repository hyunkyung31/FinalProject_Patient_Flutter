class HealthMission {
  const HealthMission({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.missionType,
    required this.frequencyType,
    required this.rewardPoints,
    required this.isActive,
    this.targetValue,
    this.targetUnit,
  });

  final int id;
  final String code;
  final String title;
  final String description;
  final String missionType;
  final double? targetValue;
  final String? targetUnit;
  final String frequencyType;
  final int rewardPoints;
  final bool isActive;

  factory HealthMission.fromJson(Map<String, dynamic> json) {
    return HealthMission(
      id: _requiredInt(json['id'], 'health_mission.id'),
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      missionType: json['mission_type']?.toString() ?? '',
      targetValue: _optionalDouble(json['target_value']),
      targetUnit: _optionalString(json['target_unit']),
      frequencyType: json['frequency_type']?.toString() ?? '',
      rewardPoints: _intOrZero(json['reward_points']),
      isActive: json['is_active'] == true,
    );
  }
}

class PatientHealthMission {
  const PatientHealthMission({
    required this.id,
    required this.healthMissionId,
    required this.healthMission,
    required this.status,
    required this.startsOn,
    required this.progressValue,
    this.endsOn,
    this.progressPercent,
    this.completedAt,
  });

  final int id;
  final int healthMissionId;
  final HealthMission healthMission;
  final String status;
  final DateTime startsOn;
  final DateTime? endsOn;
  final double progressValue;
  final double? progressPercent;
  final DateTime? completedAt;

  bool get isCompleted => status == 'COMPLETED';

  bool get isExpired => status == 'EXPIRED';

  bool get targetReached {
    final target = healthMission.targetValue;
    return target == null || progressValue >= target;
  }

  factory PatientHealthMission.fromJson(Map<String, dynamic> json) {
    final missionJson = json['health_mission'];

    if (missionJson is! Map) {
      throw const FormatException('건강 미션 정보가 올바르지 않습니다.');
    }

    final mission = HealthMission.fromJson(
      Map<String, dynamic>.from(missionJson),
    );

    return PatientHealthMission(
      id: _requiredInt(json['id'], 'patient_health_mission.id'),
      healthMissionId: _optionalInt(json['health_mission_id']) ?? mission.id,
      healthMission: mission,
      status: json['status']?.toString() ?? '',
      startsOn: _requiredDate(json['starts_on'], 'starts_on'),
      endsOn: _optionalDate(json['ends_on']),
      progressValue: _optionalDouble(json['progress_value']) ?? 0,
      progressPercent: _optionalDouble(json['progress_percent']),
      completedAt: _optionalDate(json['completed_at']),
    );
  }
}

class HealthMissionLog {
  const HealthMissionLog({
    required this.id,
    required this.patientHealthMissionId,
    required this.activityDate,
    required this.isCompleted,
    this.achievedValue,
    this.note,
    this.recordedAt,
  });

  final int id;
  final int patientHealthMissionId;
  final DateTime activityDate;
  final double? achievedValue;
  final bool isCompleted;
  final String? note;
  final DateTime? recordedAt;

  factory HealthMissionLog.fromJson(Map<String, dynamic> json) {
    return HealthMissionLog(
      id: _requiredInt(json['id'], 'health_mission_log.id'),
      patientHealthMissionId: _requiredInt(
        json['patient_health_mission'],
        'patient_health_mission',
      ),
      activityDate: _requiredDate(json['activity_date'], 'activity_date'),
      achievedValue: _optionalDouble(json['achieved_value']),
      isCompleted: json['is_completed'] == true,
      note: _optionalString(json['note']),
      recordedAt: _optionalDateTime(json['recorded_at']),
    );
  }
}

class HealthMissionCompletion {
  const HealthMissionCompletion({
    required this.mission,
    required this.alreadyCompleted,
    this.awardedPoints,
    this.balanceAfter,
  });

  final PatientHealthMission mission;
  final bool alreadyCompleted;
  final double? awardedPoints;
  final double? balanceAfter;

  factory HealthMissionCompletion.fromJson(Map<String, dynamic> json) {
    final missionJson = json['mission'];

    if (missionJson is! Map) {
      throw const FormatException('완료된 건강 미션 정보가 올바르지 않습니다.');
    }

    final transaction = json['point_transaction'];

    double? awardedPoints;
    double? balanceAfter;

    if (transaction is Map) {
      final transactionMap = Map<String, dynamic>.from(transaction);
      awardedPoints = _optionalDouble(transactionMap['amount']);
      balanceAfter = _optionalDouble(transactionMap['balance_after']);
    }

    return HealthMissionCompletion(
      mission: PatientHealthMission.fromJson(
        Map<String, dynamic>.from(missionJson),
      ),
      alreadyCompleted: json['already_completed'] == true,
      awardedPoints: awardedPoints,
      balanceAfter: balanceAfter,
    );
  }
}

int _requiredInt(Object? value, String field) {
  final parsed = _optionalInt(value);

  if (parsed == null) {
    throw FormatException('$field 값이 올바르지 않습니다.');
  }

  return parsed;
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int _intOrZero(Object? value) => _optionalInt(value) ?? 0;

double? _optionalDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _optionalString(Object? value) {
  if (value == null) return null;

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime _requiredDate(Object? value, String field) {
  final parsed = _optionalDate(value);

  if (parsed == null) {
    throw FormatException('$field 날짜가 올바르지 않습니다.');
  }

  return parsed;
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime? _optionalDateTime(Object? value) => _optionalDate(value);
