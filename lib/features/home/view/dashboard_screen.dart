import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  void open(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text('이 기능은 준비 중이에요. 지금은 메인 화면 미리보기입니다.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Row(
                children: [
                  const Text(
                    'BOMI',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '당신 곁의 건강 파트너',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '알림',
                    onPressed: () => open(context, '알림'),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘도 보미와 함께',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '김보미님,\n안녕하세요!',
                          style: TextStyle(
                            fontSize: 28,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '건강한 하루를 함께할게요.',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: '보미 캐릭터 임시 심볼',
                    child: Container(
                      width: 90,
                      height: 115,
                      decoration: BoxDecoration(
                        color: AppColors.softPink,
                        borderRadius: BorderRadius.circular(48),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: AppColors.pink,
                            size: 46,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'BOMI',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: AppColors.navy,
                        ),
                        Text(
                          '다가오는 진료',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(
                            '승인 완료',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.navy,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '10월 20일 · 오전 10:30',
                      style: TextStyle(
                        fontSize: 22,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('순환기내과 · 이보미 교수'),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => open(context, '예약 상세'),
                        label: const Text('예약 보기'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => open(context, '진료 예약'),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  '진료 예약하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '어떤 도움이 필요하세요?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      MediaQuery.textScalerOf(context).scale(14) > 22 ? 1 : 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final item in const [
                        (Icons.monitor_heart_outlined, '검사결과', '내 검사결과 확인'),
                        (Icons.medication_outlined, '처방 조회', '복용할 약 확인'),
                        (Icons.description_outlined, '진료이력', '지난 진료 돌아보기'),
                        (Icons.local_pharmacy_outlined, '주변 약국', '가까운 약국 찾기'),
                      ])
                        SizedBox(
                          width:
                              (constraints.maxWidth - 12 * (columns - 1)) /
                              columns,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => open(context, item.$2),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      item.$1,
                                      color: AppColors.blue,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      item.$2,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.$3,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '최근 소식',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => open(context, '알림 목록'),
                    child: const Text('전체 보기'),
                  ),
                ],
              ),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightBlue,
                    child: Icon(
                      Icons.event_available_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  title: const Text(
                    '진료 예약이 승인되었어요',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    '일정과 진료 정보를 확인해 주세요.',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () => open(context, '예약 상세'),
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: AppColors.softPink,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.navy,
                  ),
                  title: const Text(
                    '건강이 궁금할 땐, 보미에게',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    '건강 챗봇 만나기',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => open(context, '건강 챗봇'),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '디자인 미리보기 · 환자와 예약 정보는 예시입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.lightBlue,
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index != 0) open(context, ['홈', '예약', '건강관리', '내 정보'][index]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: AppColors.navy),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: '예약',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border_rounded),
          label: '건강관리',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: '내 정보',
        ),
      ],
    ),
  );
}
