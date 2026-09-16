class LabDisplayInfo {
  const LabDisplayInfo({
    required this.koreanName,
    required this.englishName,
    required this.code,
  });

  final String koreanName;
  final String englishName;
  final String code;

  String get subtitle {
    if (englishName.isEmpty) {
      return code;
    }

    return '$englishName · $code';
  }
}

LabDisplayInfo labDisplayInfo({
  required String code,
  required String fallbackName,
}) {
  final normalized = code.trim().toUpperCase();

  final info = switch (normalized) {
    'BUN' => const LabDisplayInfo(
      koreanName: '혈중요소질소',
      englishName: 'Blood Urea Nitrogen',
      code: 'BUN',
    ),
    'CR' => const LabDisplayInfo(
      koreanName: '크레아티닌',
      englishName: 'Creatinine',
      code: 'CR',
    ),
    'EF-TTE' => const LabDisplayInfo(
      koreanName: '좌심실 박출률',
      englishName: 'Ejection Fraction (TTE)',
      code: 'EF-TTE',
    ),
    'ESR' => const LabDisplayInfo(
      koreanName: '적혈구 침강속도',
      englishName: 'Erythrocyte Sedimentation Rate',
      code: 'ESR',
    ),
    'FBS' => const LabDisplayInfo(
      koreanName: '공복혈당',
      englishName: 'Fasting Blood Sugar',
      code: 'FBS',
    ),
    'HB' => const LabDisplayInfo(
      koreanName: '헤모글로빈',
      englishName: 'Hemoglobin',
      code: 'HB',
    ),
    'HDL' => const LabDisplayInfo(
      koreanName: 'HDL 콜레스테롤',
      englishName: 'HDL Cholesterol',
      code: 'HDL',
    ),
    'K' => const LabDisplayInfo(
      koreanName: '칼륨',
      englishName: 'Potassium',
      code: 'K',
    ),
    'LDL' => const LabDisplayInfo(
      koreanName: 'LDL 콜레스테롤',
      englishName: 'LDL Cholesterol',
      code: 'LDL',
    ),
    'LYMPH' => const LabDisplayInfo(
      koreanName: '림프구',
      englishName: 'Lymphocytes',
      code: 'Lymph',
    ),
    'NA' => const LabDisplayInfo(
      koreanName: '나트륨',
      englishName: 'Sodium',
      code: 'Na',
    ),
    'NEUT' => const LabDisplayInfo(
      koreanName: '호중구',
      englishName: 'Neutrophils',
      code: 'Neut',
    ),
    'PLT' => const LabDisplayInfo(
      koreanName: '혈소판',
      englishName: 'Platelets',
      code: 'PLT',
    ),
    'TG' => const LabDisplayInfo(
      koreanName: '중성지방',
      englishName: 'Triglycerides',
      code: 'TG',
    ),
    'WBC' => const LabDisplayInfo(
      koreanName: '백혈구',
      englishName: 'White Blood Cell Count',
      code: 'WBC',
    ),
    _ => null,
  };

  if (info != null) {
    return info;
  }

  final safeName = fallbackName.trim().isEmpty
      ? code.trim()
      : fallbackName.trim();

  return LabDisplayInfo(
    koreanName: safeName,
    englishName: '',
    code: code.trim(),
  );
}
