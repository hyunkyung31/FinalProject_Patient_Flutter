class LabResult {
  const LabResult({
    required this.id,
    required this.resultType,
    required this.version,
    required this.collectedAt,
    required this.status,
    required this.summaryText,
  });

  final int id;
  final String resultType;
  final int version;
  final DateTime collectedAt;
  final String status;
  final String summaryText;

  String get displayTitle {
    return switch (resultType.toUpperCase()) {
      'LAB_PANEL' => '혈액검사',
      _ => '검사결과',
    };
  }
}
