class LabResult {
  const LabResult({
    required this.id,
    required this.resultType,
    required this.collectedAt,
    required this.status,
    required this.summaryText,
    this.version,
  });

  final int id;
  final String resultType;
  final DateTime collectedAt;
  final String status;
  final String summaryText;

  // 기존 테스트/화면 호환을 위해 유지합니다.
  // 현재 환자 LAB API에서는 version을 반환하지 않습니다.
  final int? version;

  factory LabResult.fromJson(Map<String, dynamic> json) {
    return LabResult(
      id: _requiredInt(json['id'], 'id'),
      resultType: json['result_type']?.toString() ?? '',
      collectedAt: _requiredDateTime(json['collected_at'], 'collected_at'),
      status: json['status']?.toString() ?? '',
      summaryText: json['summary_text']?.toString() ?? '',
    );
  }

  String get displayTitle {
    return switch (resultType.toUpperCase()) {
      'LAB_PANEL' => '혈액검사',
      _ => '검사결과',
    };
  }
}

class LabResultDetail {
  const LabResultDetail({required this.result, required this.measurements});

  final LabResult result;
  final List<LabMeasurement> measurements;

  factory LabResultDetail.fromJson(Map<String, dynamic> json) {
    final rawMeasurements = json['measurements'];

    return LabResultDetail(
      result: LabResult.fromJson(json),
      measurements: rawMeasurements is List
          ? rawMeasurements
                .whereType<Map>()
                .map(
                  (item) =>
                      LabMeasurement.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const <LabMeasurement>[],
    );
  }
}

class LabMeasurement {
  const LabMeasurement({
    required this.id,
    required this.code,
    required this.name,
    this.clinicalVariableId,
    this.valueNumeric,
    this.valueText,
    this.valueBoolean,
    this.unit,
    this.referenceRangeId,
    this.referenceMin,
    this.referenceMax,
    this.referenceText,
    this.abnormalFlag,
    this.validationStatus,
    this.measuredAt,
  });

  final int id;
  final int? clinicalVariableId;
  final String code;
  final String name;
  final double? valueNumeric;
  final String? valueText;
  final bool? valueBoolean;
  final String? unit;
  final int? referenceRangeId;
  final double? referenceMin;
  final double? referenceMax;
  final String? referenceText;
  final String? abnormalFlag;
  final String? validationStatus;
  final DateTime? measuredAt;

  factory LabMeasurement.fromJson(Map<String, dynamic> json) {
    return LabMeasurement(
      id: _requiredInt(json['measurement_id'] ?? json['id'], 'measurement_id'),
      clinicalVariableId: _nullableInt(json['clinical_variable_id']),
      code: json['code']?.toString() ?? '',
      name: json['display_name']?.toString() ?? json['name']?.toString() ?? '',
      valueNumeric: _nullableDouble(json['value_numeric'] ?? json['value']),
      valueText: json['value_text']?.toString(),
      valueBoolean: json['value_boolean'] is bool
          ? json['value_boolean'] as bool
          : null,
      unit: json['unit']?.toString(),
      referenceRangeId: _nullableInt(json['reference_range_id']),
      referenceMin: _nullableDouble(json['reference_min']),
      referenceMax: _nullableDouble(json['reference_max']),
      referenceText: json['reference_text']?.toString(),
      abnormalFlag: json['abnormal_flag']?.toString(),
      validationStatus: json['validation_status']?.toString(),
      measuredAt: _nullableDateTime(json['measured_at']),
    );
  }

  String get displayValue {
    final numeric = valueNumeric;
    if (numeric != null) {
      return _compactNumber(numeric);
    }

    final text = valueText?.trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }

    final boolean = valueBoolean;
    if (boolean != null) {
      return boolean.toString();
    }

    return '-';
  }

  String get displayUnit {
    final value = unit?.trim();
    return value == null || value.isEmpty ? '' : value;
  }

  String get displayReference {
    if (referenceMin != null && referenceMax != null) {
      return '${_compactNumber(referenceMin!)} ~ ${_compactNumber(referenceMax!)}';
    }

    if (referenceMin != null) {
      return '${_compactNumber(referenceMin!)} 이상';
    }

    if (referenceMax != null) {
      return '${_compactNumber(referenceMax!)} 이하';
    }

    final text = referenceText?.trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }

    return '-';
  }

  String get normalizedFlag => abnormalFlag?.toUpperCase() ?? '';
}

class LabTrend {
  const LabTrend({
    required this.code,
    required this.results,
    this.displayName,
    this.unit,
  });

  final String code;
  final String? displayName;
  final String? unit;
  final List<LabTrendPoint> results;

  factory LabTrend.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];

    return LabTrend(
      code: json['code']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      unit: json['unit']?.toString(),
      results: rawResults is List
          ? rawResults
                .whereType<Map>()
                .map(
                  (item) =>
                      LabTrendPoint.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const <LabTrendPoint>[],
    );
  }
}

class LabTrendPoint {
  const LabTrendPoint({
    required this.measuredAt,
    this.value,
    this.abnormalFlag,
  });

  final DateTime measuredAt;
  final double? value;
  final String? abnormalFlag;

  factory LabTrendPoint.fromJson(Map<String, dynamic> json) {
    return LabTrendPoint(
      measuredAt: _requiredDateTime(json['measured_at'], 'measured_at'),
      value: _nullableDouble(json['value']),
      abnormalFlag: json['abnormal_flag']?.toString(),
    );
  }

  String get normalizedFlag => abnormalFlag?.toUpperCase() ?? '';
}

int _requiredInt(Object? value, String field) {
  final parsed = _nullableInt(value);
  if (parsed == null) {
    throw FormatException('$field 값이 올바르지 않습니다.');
  }
  return parsed;
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

double? _nullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

DateTime _requiredDateTime(Object? value, String field) {
  final parsed = _nullableDateTime(value);
  if (parsed == null) {
    throw FormatException('$field 값이 올바르지 않습니다.');
  }
  return parsed;
}

DateTime? _nullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

String _compactNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
