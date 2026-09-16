enum LabEducationCategory {
  cardiovascularMetabolic,
  kidneyElectrolyte,
  bloodImmune,
}

class LabEducationInfo {
  const LabEducationInfo({
    required this.code,
    required this.displayPriority,
    required this.category,
    required this.title,
    required this.summary,
    required this.whyItMatters,
    required this.sourceLabel,
    this.note,
  });

  final String code;

  // 환자 앱의 표시 순서이며 임상적 중증도 순위가 아닙니다.
  final int displayPriority;

  final LabEducationCategory category;
  final String title;
  final String summary;
  final String whyItMatters;
  final String? note;
  final String sourceLabel;
}

const labEducationInfoMap = <String, LabEducationInfo>{
  'LDL': LabEducationInfo(
    code: 'LDL',
    displayPriority: 1,
    category: LabEducationCategory.cardiovascularMetabolic,
    title: 'LDL 콜레스테롤',
    summary: '혈액 속 LDL 콜레스테롤의 양을 확인하는 검사예요.',
    whyItMatters: 'LDL 콜레스테롤은 혈관 벽에 쌓일 수 있어 심장과 혈관 건강을 살펴볼 때 중요하게 확인해요.',
    note: '검사 결과는 다른 심혈관 위험요인과 함께 해석해요.',
    sourceLabel: '2026 ACC/AHA Dyslipidemia Guideline · NIH MedlinePlus',
  ),
  'FBS': LabEducationInfo(
    code: 'FBS',
    displayPriority: 2,
    category: LabEducationCategory.cardiovascularMetabolic,
    title: '공복혈당',
    summary: '공복 상태에서 혈액 속 포도당의 양을 확인하는 검사예요.',
    whyItMatters: '혈당 상태와 당 대사를 살펴보고 당뇨병이나 전당뇨병을 확인할 때 사용하는 지표예요.',
    note: '공복혈당은 다른 검사 결과와 함께 종합적으로 판단할 수 있어요.',
    sourceLabel: 'ADA Standards of Care in Diabetes—2026 · NIH MedlinePlus',
  ),
  'TG': LabEducationInfo(
    code: 'TG',
    displayPriority: 4,
    category: LabEducationCategory.cardiovascularMetabolic,
    title: '중성지방',
    summary: '혈액 속 중성지방의 양을 확인하는 검사예요.',
    whyItMatters: '중성지방은 몸이 에너지를 저장하는 형태의 지방으로, 혈중 지방 상태와 심혈관 건강을 살펴볼 때 참고해요.',
    note: '식사, 음주, 체중과 같은 여러 요인의 영향을 받을 수 있어요.',
    sourceLabel: '2026 ACC/AHA Dyslipidemia Guideline · NIH MedlinePlus',
  ),
  'HDL': LabEducationInfo(
    code: 'HDL',
    displayPriority: 3,
    category: LabEducationCategory.cardiovascularMetabolic,
    title: 'HDL 콜레스테롤',
    summary: '혈액 속 HDL 콜레스테롤의 양을 확인하는 검사예요.',
    whyItMatters:
        'HDL은 몸의 여러 곳에 있는 콜레스테롤을 간으로 운반하는 과정에 관여하며 심혈관 위험을 살펴볼 때 함께 확인해요.',
    note: 'HDL은 LDL, 중성지방 등 다른 지질 수치와 함께 살펴봐요.',
    sourceLabel: '2026 ACC/AHA Dyslipidemia Guideline · NIH MedlinePlus',
  ),
  'CR': LabEducationInfo(
    code: 'CR',
    displayPriority: 5,
    category: LabEducationCategory.kidneyElectrolyte,
    title: '크레아티닌',
    summary: '근육 활동 과정에서 생기는 크레아티닌의 혈중 농도를 확인하는 검사예요.',
    whyItMatters: '크레아티닌은 신장이 혈액 속 노폐물을 얼마나 잘 걸러내는지 살펴볼 때 주로 참고해요.',
    note: '근육량이나 여러 건강 상태에 따라서도 수치가 달라질 수 있어요.',
    sourceLabel: 'KDIGO 2024 CKD Guideline · NIH MedlinePlus',
  ),
  'K': LabEducationInfo(
    code: 'K',
    displayPriority: 6,
    category: LabEducationCategory.kidneyElectrolyte,
    title: '칼륨',
    summary: '혈액 속 칼륨의 양을 확인하는 검사예요.',
    whyItMatters: '칼륨은 심장 박동과 신경·근육이 정상적으로 기능하는 데 필요한 중요한 전해질이에요.',
    note: '신장 기능이나 복용 중인 약물 등에 따라 수치가 달라질 수 있어요.',
    sourceLabel: 'KDIGO 2024 CKD Guideline · NIH MedlinePlus',
  ),
  'NA': LabEducationInfo(
    code: 'Na',
    displayPriority: 7,
    category: LabEducationCategory.kidneyElectrolyte,
    title: '나트륨',
    summary: '혈액 속 나트륨의 양을 확인하는 검사예요.',
    whyItMatters: '나트륨은 몸의 수분과 전해질 균형을 유지하는 데 중요한 역할을 해요.',
    note: '수분 상태, 신장 기능, 약물 등 여러 요인의 영향을 받을 수 있어요.',
    sourceLabel: 'NIH MedlinePlus',
  ),
  'BUN': LabEducationInfo(
    code: 'BUN',
    displayPriority: 8,
    category: LabEducationCategory.kidneyElectrolyte,
    title: '혈중요소질소',
    summary: '단백질이 분해될 때 만들어지는 요소질소의 혈중 농도를 확인하는 검사예요.',
    whyItMatters: '요소질소는 주로 신장을 통해 배출되므로 신장 기능과 몸의 수분 상태를 살펴볼 때 참고해요.',
    note: '식사와 수분 상태 등에도 영향을 받을 수 있어 다른 검사와 함께 해석해요.',
    sourceLabel: 'KDIGO 2024 CKD Guideline · NIH MedlinePlus',
  ),
  'HB': LabEducationInfo(
    code: 'HB',
    displayPriority: 9,
    category: LabEducationCategory.bloodImmune,
    title: '헤모글로빈',
    summary: '적혈구 안에서 산소를 운반하는 헤모글로빈의 양을 확인하는 검사예요.',
    whyItMatters: '몸의 조직에 산소를 전달하는 능력과 적혈구 상태를 살펴볼 때 참고해요.',
    note: '헤모글로빈은 다른 혈액검사 결과와 함께 살펴봐요.',
    sourceLabel: 'NIH MedlinePlus',
  ),
  'PLT': LabEducationInfo(
    code: 'PLT',
    displayPriority: 10,
    category: LabEducationCategory.bloodImmune,
    title: '혈소판',
    summary: '혈액 속 혈소판의 수를 확인하는 검사예요.',
    whyItMatters: '혈소판은 상처가 생겼을 때 혈액이 굳어 출혈을 멈추는 과정에 중요한 역할을 해요.',
    note: '혈소판 수치는 출혈·응고 상태를 평가할 때 다른 검사와 함께 확인해요.',
    sourceLabel: 'NIH MedlinePlus',
  ),
  'WBC': LabEducationInfo(
    code: 'WBC',
    displayPriority: 11,
    category: LabEducationCategory.bloodImmune,
    title: '백혈구',
    summary: '혈액 속 백혈구의 수를 확인하는 검사예요.',
    whyItMatters: '백혈구는 감염과 질병으로부터 몸을 보호하는 면역 기능에 중요한 역할을 해요.',
    note: '백혈구의 종류와 다른 검사 결과를 함께 보면 면역 상태를 더 자세히 살펴볼 수 있어요.',
    sourceLabel: 'NIH MedlinePlus',
  ),
  'NEUT': LabEducationInfo(
    code: 'Neut',
    displayPriority: 12,
    category: LabEducationCategory.bloodImmune,
    title: '호중구',
    summary: '백혈구 중 호중구가 차지하는 양이나 비율을 확인하는 검사예요.',
    whyItMatters: '호중구는 몸에 들어온 세균과 여러 감염원에 빠르게 대응하는 면역세포예요.',
    note: '백혈구 수와 다른 백혈구 종류를 함께 살펴봐요.',
    sourceLabel: 'NIH MedlinePlus Blood Differential',
  ),
  'LYMPH': LabEducationInfo(
    code: 'Lymph',
    displayPriority: 13,
    category: LabEducationCategory.bloodImmune,
    title: '림프구',
    summary: '백혈구 중 림프구가 차지하는 양이나 비율을 확인하는 검사예요.',
    whyItMatters: '림프구에는 B세포와 T세포 등이 있으며 감염원에 대응하는 면역 기능에 관여해요.',
    note: '림프구 수치만으로 원인을 판단하지 않고 다른 혈액검사와 함께 살펴봐요.',
    sourceLabel: 'NIH MedlinePlus Blood Differential',
  ),
  'ESR': LabEducationInfo(
    code: 'ESR',
    displayPriority: 14,
    category: LabEducationCategory.bloodImmune,
    title: '적혈구 침강속도',
    summary: '적혈구가 일정 시간 동안 얼마나 빠르게 가라앉는지 확인하는 검사예요.',
    whyItMatters: '몸 안에 염증 반응이 있는지 간접적으로 살펴볼 때 참고하는 검사예요.',
    note: 'ESR만으로 염증의 원인이나 특정 질환을 판단할 수는 없어요.',
    sourceLabel: 'NIH MedlinePlus ESR',
  ),
};

LabEducationInfo? labEducationInfo(String code) {
  return labEducationInfoMap[code.trim().toUpperCase()];
}

int labDisplayPriority(String code) {
  return labEducationInfo(code)?.displayPriority ?? 999;
}
