class PatientFeatureFlags {
  const PatientFeatureFlags._();

  // Clinical 심혈관 위험도 기능은 구현을 보존하되 현재 환자 앱에서는 노출하지 않는다.
  // 추후 재사용 시 true로 변경하면 검사결과 진입점을 다시 표시할 수 있다.
  static const bool showClinicalRisk = false;
}
