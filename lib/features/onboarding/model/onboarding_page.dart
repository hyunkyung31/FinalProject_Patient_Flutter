class OnboardingPage {
  const OnboardingPage(this.image, this.title, this.description);

  final String image;
  final String title;
  final String description;

  static const pages = [
    OnboardingPage(
      '01_health_dashboard',
      '건강정보를 한눈에 확인해요',
      '진료 일정과 공개된 검사결과를 보미와 함께 확인하세요.',
    ),
    OnboardingPage(
      '02_login_fingerprint',
      '간편하게 시작해요',
      '소셜 로그인으로 시작하고, 본인인증과 병원기록 연결을 진행해요.',
    ),
    OnboardingPage(
      '03_appointment_medical_records',
      '예약과 기록을 편리하게',
      '진료를 예약하고 승인 상태와 연결된 의료기록을 확인해요.',
    ),
    OnboardingPage(
      '04_blood_cad_cac',
      '검사결과를 차근차근 살펴봐요',
      '혈액검사 수치와 의료진이 공개한 AI 분석 결과를 확인해요.',
    ),
    OnboardingPage(
      '05_ai_clinician_pdf',
      '의료진 소견을 함께 확인해요',
      'AI 분석과 의료진 소견을 구분해 읽고, 공개된 보고서를 확인해요.',
    ),
    OnboardingPage(
      '06_health_mission_rewards',
      '작은 건강 습관을 이어가요',
      '건강 미션을 실천하고 활동 기록과 리워드를 확인해요.',
    ),
    OnboardingPage(
      '07_ai_chatbot_prescription_pharmacy',
      '일상에서도 보미와 함께해요',
      '건강 챗봇, 처방 조회, 주변 약국 찾기를 이용해 보세요.',
    ),
  ];
}
