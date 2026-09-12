import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/bomi_greeting.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../reservation/view/reservation_list_screen.dart';
import '../../reservation/view/reservation_screen.dart';
import '../../reservation/repository/reservation_repository.dart';
import '../../patient_services/view/patient_services_screen.dart';
import '../../notification/view/notification_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.reservationRepository,
    this.onLogout,
    this.patientLinked,
    this.onRefreshLink,
  });
  final bool? patientLinked;
  final Future<void> Function()? onRefreshLink;
  final Future<void> Function()? onLogout;
  final ReservationRepository? reservationRepository;
  Future<void> openService(BuildContext context, String section) async {
    final repository = reservationRepository;
    if (repository == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            PatientServicesScreen(repository: repository, section: section),
      ),
    );
    if (!context.mounted) return;
    await onRefreshLink?.call();
  }

  void openReservations(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ReservationListScreen(repository: reservationRepository),
      ),
    );
  }

  void open(BuildContext context, String title) {
    if (reservationRepository != null && ['알림', '알림 목록'].contains(title)) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              NotificationScreen(reservationRepository: reservationRepository!),
        ),
      );
      return;
    }
    final dashboardContext = context;
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
              Text(
                patientLinked == false &&
                        ['검사결과', '처방 조회', '진료이력'].contains(title)
                    ? '병원기록 연결 후 확인할 수 있어요. 조회 화면은 준비 중이에요.'
                    : '이 기능은 준비 중이에요.',
              ),
              if (patientLinked == false &&
                  reservationRepository != null &&
                  ['검사결과', '처방 조회', '진료이력'].contains(title))
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openService(dashboardContext, 'link');
                  },
                  child: const Text('병원기록 연결'),
                ),
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
                    tooltip: '앱 사용 가이드',
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (guideContext) => OnboardingScreen(
                          onComplete: () async =>
                              Navigator.of(guideContext).pop(),
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  if (reservationRepository != null)
                    PatientNotificationButton(
                      repository: reservationRepository!,
                    )
                  else
                    IconButton(
                      tooltip: '알림',
                      onPressed: () => open(context, '알림'),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.navy,
                      ),
                    ),
                  if (onLogout != null)
                    IconButton(
                      tooltip: '로그아웃',
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, color: AppColors.navy),
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
                          '안녕하세요!\n반가워요',
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
                  const BomiGreeting(),
                ],
              ),
              const SizedBox(height: 24),
              if (patientLinked != null && reservationRepository != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          patientLinked!
                              ? '병원기록이 연결되어 있어요'
                              : '아직 연결된 병원기록이 없어요',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          patientLinked!
                              ? '내 정보에서 연결된 환자정보를 확인해 주세요.'
                              : '처음 방문하셔도 아래에서 진료를 예약할 수 있어요.',
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => openService(
                                context,
                                patientLinked! ? 'profile' : 'link',
                              ),
                              child: Text(
                                patientLinked! ? '내 환자정보' : '병원기록 연결',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                            '예약 안내',
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
                      '예약 일정을 확인해 보세요',
                      style: TextStyle(
                        fontSize: 22,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('예약 목록에서 진료 일정과 승인 상태를 확인할 수 있어요.'),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => openReservations(context),
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
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        ReservationScreen(repository: reservationRepository),
                  ),
                ),
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
                    '예약 소식을 확인해 보세요',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    '일정과 진료 정보를 확인해 주세요.',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () => openReservations(context),
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
                '당신의 건강한 하루를 보미가 함께할게요.',
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
        if (index == 1) {
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  ReservationListScreen(repository: reservationRepository),
            ),
          );
          return;
        }
        if (index == 3 && reservationRepository != null) {
          openService(context, 'menu');
          return;
        }
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
