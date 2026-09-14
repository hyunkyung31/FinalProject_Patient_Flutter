// 환자에게 공개된 AI 분석 결과 전체 구조
class PatientAIResult {
  const PatientAIResult({
    required this.id,
    required this.analysisId,
    required this.resultType,
    required this.summaryText,
    required this.confidence,
    required this.generatedAt,
    required this.status,
    required this.detections,
    required this.lesions,
    required this.cacScores,
    required this.explanations,
    this.keyFactors = const [],
  });

  final int id;
  final int analysisId;
  final String resultType;
  final String summaryText;
  final double? confidence;
  final DateTime generatedAt;
  final String status;

  final List<PatientAIDetection> detections;
  final List<PatientAILesion> lesions;
  final List<PatientAICacScore> cacScores;
  final List<PatientAIExplanation> explanations;
  final List<PatientAIKeyFactor> keyFactors;

  // 환자 API JSON을 앱 모델로 변환
  factory PatientAIResult.fromJson(Map<String, dynamic> json) {
    return PatientAIResult(
      id: _requiredInt(json['id'], 'id'),
      analysisId: _requiredInt(json['analysis_id'], 'analysis_id'),
      resultType: json['result_type']?.toString() ?? '',
      summaryText: json['summary_text']?.toString() ?? '',
      confidence: _nullableDouble(json['confidence']),
      generatedAt: _requiredDateTime(json['generated_at'], 'generated_at'),
      status: json['status']?.toString() ?? '',
      detections: _parseList(json['detections'], PatientAIDetection.fromJson),
      lesions: _parseList(json['lesions'], PatientAILesion.fromJson),
      cacScores: _parseList(json['cac_scores'], PatientAICacScore.fromJson),
      explanations: _parseList(
        json['explanations'],
        PatientAIExplanation.fromJson,
      ),
    );
  }
}

// 협착·플라크 등 AI 탐지 결과
class PatientAIDetection {
  const PatientAIDetection({
    required this.findingType,
    required this.arterySegment,
    required this.confidence,
    required this.severity,
  });

  final String findingType;
  final String arterySegment;
  final double? confidence;
  final String severity;

  // 탐지 결과 JSON 변환
  factory PatientAIDetection.fromJson(Map<String, dynamic> json) {
    return PatientAIDetection(
      findingType: json['finding_type']?.toString() ?? '',
      arterySegment: json['artery_segment']?.toString() ?? '',
      confidence: _nullableDouble(json['confidence']),
      severity: json['severity']?.toString() ?? '',
    );
  }
}

// 관상동맥 병변 관련 AI 결과
class PatientAILesion {
  const PatientAILesion({
    required this.arteryName,
    required this.segmentName,
    required this.stenosisPercent,
    required this.lesionVolumeMm3,
    required this.severityGrade,
  });

  final String arteryName;
  final String segmentName;
  final double? stenosisPercent;
  final double? lesionVolumeMm3;
  final String severityGrade;

  // 병변 결과 JSON 변환
  factory PatientAILesion.fromJson(Map<String, dynamic> json) {
    return PatientAILesion(
      arteryName: json['artery_name']?.toString() ?? '',
      segmentName: json['segment_name']?.toString() ?? '',
      stenosisPercent: _nullableDouble(json['stenosis_percent']),
      lesionVolumeMm3: _nullableDouble(json['lesion_volume_mm3']),
      severityGrade: json['severity_grade']?.toString() ?? '',
    );
  }
}

// 관상동맥 석회화 AI 결과
class PatientAICacScore {
  const PatientAICacScore({
    required this.scoreValue,
    required this.ladScore,
    required this.lcxScore,
    required this.rcaScore,
    required this.percentile,
    required this.riskCategory,
    required this.calculatedAt,
  });

  final double? scoreValue;
  final double? ladScore;
  final double? lcxScore;
  final double? rcaScore;
  final double? percentile;
  final String riskCategory;
  final DateTime? calculatedAt;

  // 석회화 결과 JSON 변환
  factory PatientAICacScore.fromJson(Map<String, dynamic> json) {
    return PatientAICacScore(
      scoreValue: _nullableDouble(json['score_value']),
      ladScore: _nullableDouble(json['lad_score']),
      lcxScore: _nullableDouble(json['lcx_score']),
      rcaScore: _nullableDouble(json['rca_score']),
      percentile: _nullableDouble(json['percentile']),
      riskCategory: json['risk_category']?.toString() ?? '',
      calculatedAt: _nullableDateTime(json['calculated_at']),
    );
  }
}

// 환자에게 제공되는 AI 설명 문구
// 환자 화면용 주요 영향 요인
class PatientAIKeyFactor {
  const PatientAIKeyFactor({
    required this.label,
    required this.impact,
    required this.impactLabel,
  });

  final String label;
  final double? impact;
  final String impactLabel;

  // 영향 요인 JSON 변환
  factory PatientAIKeyFactor.fromJson(Map<String, dynamic> json) {
    return PatientAIKeyFactor(
      label: json['label']?.toString() ?? '',
      impact: _nullableDouble(json['impact']),
      impactLabel: json['impact_label']?.toString() ?? '',
    );
  }
}

class PatientAIExplanation {
  const PatientAIExplanation({
    required this.explanationType,
    required this.summaryText,
    required this.generatedAt,
  });

  final String explanationType;
  final String summaryText;
  final DateTime? generatedAt;

  // AI 설명 JSON 변환
  factory PatientAIExplanation.fromJson(Map<String, dynamic> json) {
    return PatientAIExplanation(
      explanationType: json['explanation_type']?.toString() ?? '',
      summaryText: json['summary_text']?.toString() ?? '',
      generatedAt: _nullableDateTime(json['generated_at']),
    );
  }
}

// JSON 배열을 지정한 모델 목록으로 변환
List<T> _parseList<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map>()
      .map((item) => parser(Map<String, dynamic>.from(item)))
      .toList();
}

// 필수 정수값 검증 및 변환
int _requiredInt(Object? value, String fieldName) {
  if (value is int) {
    return value;
  }

  final parsed = int.tryParse(value?.toString() ?? '');

  if (parsed == null) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }

  return parsed;
}

// 숫자 또는 문자열 형태의 소수값 변환
double? _nullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

// 필수 날짜값 검증 및 변환
DateTime _requiredDateTime(Object? value, String fieldName) {
  final parsed = _nullableDateTime(value);

  if (parsed == null) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }

  return parsed;
}

// 선택 날짜값 변환
DateTime? _nullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
