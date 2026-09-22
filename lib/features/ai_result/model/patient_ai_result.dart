// 환자에게 공개된 AI 분석 결과 전체 구조
class PatientAIResult {
  const PatientAIResult({
    required this.id,
    required this.analysisId,
    this.analysisType = '',
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
    this.images = const [],
    this.examinationId,
    this.clinical,
  });

  final int id;
  final int analysisId;
  final String analysisType;
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
  final List<PatientAIImage> images;
  final int? examinationId;
  final PatientAIClinical? clinical;

  // 환자 API JSON을 앱 모델로 변환
  factory PatientAIResult.fromJson(Map<String, dynamic> json) {
    return PatientAIResult(
      id: _requiredInt(json['id'], 'id'),
      analysisId: _requiredInt(json['analysis_id'], 'analysis_id'),
      analysisType: json['analysis_type']?.toString() ?? '',
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
      images: _parseList(json['images'], PatientAIImage.fromJson),
      examinationId: _nullableInt(json['examination_id']),
      clinical: _parseClinical(json),
    );
  }
}

// 협착·플라크 등 AI 탐지 결과
// 환자용 Clinical AI 예측값
class PatientAIClinical {
  const PatientAIClinical({
    this.probability,
  });

  final double? probability;

  factory PatientAIClinical.fromJson(
    Map<String, dynamic> json,
  ) {
    return PatientAIClinical(
      probability: _nullableDouble(json['probability']),
    );
  }
}


// 환자에게 공개된 XCA/CCTA 파생 미리보기 이미지
class PatientAIImage {
  const PatientAIImage({
    required this.kind,
    required this.label,
    required this.url,
    this.expiresIn,
    this.frameId,
    this.sequenceNo,
    this.frameIndex,
  });

  final String kind;
  final String label;
  final String url;
  final int? expiresIn;

  // XCA frame 이미지인 경우에만 제공될 수 있다.
  final int? frameId;
  final int? sequenceNo;
  final int? frameIndex;

  factory PatientAIImage.fromJson(Map<String, dynamic> json) {
    return PatientAIImage(
      kind: json['kind']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      expiresIn: _nullableInt(json['expires_in']),
      frameId: _nullableInt(json['frame_id']),
      sequenceNo: _nullableInt(json['sequence_no']),
      frameIndex: _nullableInt(json['frame_index']),
    );
  }
}

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

PatientAIClinical? _parseClinical(
  Map<String, dynamic> json,
) {
  final rawClinical = json['clinical'];

  if (rawClinical is Map) {
    return PatientAIClinical.fromJson(
      Map<String, dynamic>.from(rawClinical),
    );
  }

  // 구버전 API에서는 Clinical probability가 confidence에 저장되어 있다.
  final analysisType =
      json['analysis_type']?.toString().trim().toUpperCase();

  if (analysisType == 'CLINICAL') {
    return PatientAIClinical(
      probability: _nullableDouble(json['confidence']),
    );
  }

  return null;
}

// 숫자 또는 문자열 형태의 정수값 변환
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
