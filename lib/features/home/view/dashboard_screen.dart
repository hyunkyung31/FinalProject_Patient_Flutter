import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_preferences.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../reservation/view/reservation_list_screen.dart';
import '../../reservation/view/reservation_screen.dart';
import '../../reservation/model/patient_reservation.dart';
import '../../reservation/repository/reservation_repository.dart';
import '../../patient_services/view/patient_services_screen.dart';
import '../../notification/view/notification_screen.dart';
import '../../pharmacy/pharmacy_screen.dart';
import '../../pharmacy/pharmacy_repository.dart';
import '../../health_management/repository/health_mission_repository.dart';
import '../../health_management/view/health_management_screen.dart';
import '../../reward/repository/reward_repository.dart';
import '../../reward/view/reward_screen.dart';
import '../../prescription/repository/patient_prescription_repository.dart';
import '../../prescription/view/patient_prescription_list_screen.dart';
import '../../ai_result/repository/patient_ai_result_repository.dart';
import '../../ai_result/view/patient_ai_result_list_screen.dart';
import '../../lab_result/repository/lab_result_repository.dart';
import '../../lab_result/view/lab_result_list_screen.dart';
import '../../patient_report/repository/patient_report_repository.dart';
import '../../patient_report/view/patient_report_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.reservationRepository,
    this.onLogout,
    this.patientLinked,
    this.patientName,
    this.onRefreshLink,
  });

  final bool? patientLinked;
  final String? patientName;
  final Future<void> Function()? onRefreshLink;
  final Future<void> Function()? onLogout;
  final ReservationRepository? reservationRepository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _pageFor(int index) {
    final repository = widget.reservationRepository;

    switch (index) {
      case 0:
        return _DashboardHome(
          reservationRepository: repository,
          onLogout: widget.onLogout,
          patientLinked: widget.patientLinked,
          patientName: widget.patientName,
          onRefreshLink: widget.onRefreshLink,
          embedded: true,
          onSelectTab: _selectTab,
        );
      case 1:
        return ReservationListScreen(repository: repository, embedded: true);
      case 2:
        if (widget.patientLinked == true && repository != null) {
          return HealthManagementScreen(
            repository: PatientHealthMissionRepository(repository.client),
            rewardRepository: PatientRewardRepository(repository.client),
            embedded: true,
          );
        }
        if (repository != null) {
          return PatientServicesScreen(
            repository: repository,
            section: 'link',
            embedded: true,
          );
        }
        return const SizedBox.shrink();
      case 3:
        if (repository != null) {
          return PatientServicesScreen(
            repository: repository,
            embedded: true,
            patientName: widget.patientName,
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _PersistentTopBar(
            repository: widget.reservationRepository,
            tinted: _selectedIndex == 0,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(4, _pageFor),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lightBlue,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '\uD648',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '\uC608\uC57D',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: '\uAC74\uAC15\uAD00\uB9AC',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '\uB0B4 \uC815\uBCF4',
          ),
        ],
      ),
    );
  }
}

class _PersistentTopBar extends StatelessWidget {
  const _PersistentTopBar({required this.repository, required this.tinted});

  final ReservationRepository? repository;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: tinted
                ? const LinearGradient(
                    colors: [Color(0xFFDCEBFF), Color(0xFFE9E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: tinted ? null : Colors.white,
            border: tinted
                ? null
                : const Border(bottom: BorderSide(color: Color(0xFFE7EDF7))),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/bomi/dugn_logo.png',
                height: 28,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const Spacer(),
              const _TextScaleButton(),
              IconButton(
                tooltip: '\uC628\uBCF4\uB529',
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (guideContext) => OnboardingScreen(
                      onComplete: () async => Navigator.of(guideContext).pop(),
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.navy,
                ),
              ),
              if (repository != null)
                PatientNotificationButton(repository: repository!)
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({
    super.key,
    this.reservationRepository,
    this.onLogout,
    this.patientLinked,
    this.patientName,
    this.onRefreshLink,
    this.embedded = false,
    this.onSelectTab,
  });
  final bool? patientLinked;
  final String? patientName;
  final Future<void> Function()? onRefreshLink;
  final Future<void> Function()? onLogout;
  final ReservationRepository? reservationRepository;
  final bool embedded;
  final ValueChanged<int>? onSelectTab;
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

  // 건강관리 화면 진입 로직을 홈 배너와 하단 탭에서 함께 사용한다.
  void openHealthManagement(BuildContext context) {
    if (embedded && onSelectTab != null) {
      onSelectTab!(2);
      return;
    }
    final repository = reservationRepository;

    if (patientLinked == true && repository != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => HealthManagementScreen(
            repository: PatientHealthMissionRepository(repository.client),
            rewardRepository: PatientRewardRepository(repository.client),
          ),
        ),
      );
      return;
    }

    open(context, '건강관리');
  }

  Future<void> openReservations(BuildContext context) async {
    if (embedded && onSelectTab != null) {
      onSelectTab!(1);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ReservationListScreen(repository: reservationRepository),
      ),
    );
  }

  void open(BuildContext context, String title) {
    if (title == '주변 약국' && reservationRepository != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PharmacyScreen(
            repository: PharmacyRepository(reservationRepository!.client),
          ),
        ),
      );
      return;
    }
    if (reservationRepository != null && ['알림', '알림 목록'].contains(title)) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              NotificationScreen(reservationRepository: reservationRepository!),
        ),
      );
      return;
    }
    // 연결된 환자의 기능 화면으로 이동
    final repository = reservationRepository;
    if (patientLinked == true && repository != null) {
      final Widget? screen = switch (title) {
        '검사결과' => LabResultListScreen(
          repository: PatientLabResultRepository(repository.client),
        ),
        'AI 결과' => PatientAIResultListScreen(
          repository: PatientAIResultRepository(repository.client),
        ),
        '리포트' => PatientReportListScreen(
          repository: PatientReportRepository(repository.client),
        ),
        '처방 조회' => PatientPrescriptionListScreen(
          repository: PatientPrescriptionRepository(repository.client),
        ),
        '리워드' => RewardScreen(
          repository: PatientRewardRepository(repository.client),
        ),
        _ => null,
      };

      if (screen != null) {
        Navigator.of(
          context,
        ).push<void>(MaterialPageRoute(builder: (_) => screen));
        return;
      }
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
                        [
                          '검사결과',
                          'AI 결과',
                          '리포트',
                          '처방 조회',
                          '리워드',
                          '건강관리',
                        ].contains(title)
                    ? '병원기록 연결 후 확인할 수 있어요. 조회 화면은 준비 중이에요.'
                    : '이 기능은 준비 중이에요.',
              ),
              if (patientLinked == false &&
                  reservationRepository != null &&
                  [
                    '검사결과',
                    'AI 결과',
                    '리포트',
                    '처방 조회',
                    '리워드',
                    '건강관리',
                  ].contains(title))
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
    // SafeArea 바깥의 상태바 영역도 Hero와 자연스럽게 이어준다.
    backgroundColor: const Color(0xFFF8FAFC),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final compact = constraints.maxHeight < 700 || textScale >= 1.5;

            // 큰 글씨에서는 주요 기능을 2열로 바꿔 여유를 확보한다.
            final menuColumns = 3;

            final menuItems = <(IconData, String)>[
              (Icons.science_outlined, '검사결과'),
              (Icons.insights_outlined, 'AI 결과'),
              (Icons.picture_as_pdf_outlined, '리포트'),
              (Icons.medication_outlined, '처방 조회'),
              (Icons.local_pharmacy_outlined, '주변 약국'),
              (Icons.card_giftcard_rounded, '리워드'),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단 Hero 영역은 기기 배경과 자연스럽게 이어지도록 Flutter로 그린다.
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      embedded ? 12 : MediaQuery.paddingOf(context).top + 8,
                      18,
                      18,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDCEBFF), Color(0xFFE9E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!embedded)
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/bomi/dugn_logo.png',
                                height: 34,
                                fit: BoxFit.contain,
                                alignment: Alignment.centerLeft,
                                excludeFromSemantics: true,
                              ),
                              const Spacer(),
                              const _TextScaleButton(),
                              IconButton(
                                tooltip: '앱 사용 가이드',
                                onPressed: () =>
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (guideContext) =>
                                            OnboardingScreen(
                                              onComplete: () async =>
                                                  Navigator.of(
                                                    guideContext,
                                                  ).pop(),
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
                                  icon: const Icon(
                                    Icons.logout,
                                    color: AppColors.navy,
                                  ),
                                ),
                            ],
                          ),
                        SizedBox(height: compact ? 12 : 18),

                        // 인사말과 보미를 겹쳐 배치한다.
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                right: compact ? 105 : 140,
                                bottom: compact ? 10 : 18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientName?.trim().isNotEmpty == true
                                        ? '안녕하세요, ${patientName!.trim()}님!'
                                        : '안녕하세요!',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 24,
                                      height: 1.12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '오늘도 보미와 건강한 하루 함께해요.',
                                    style: TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: -58,
                              child: SizedBox(
                                width: compact ? 128 : 158,
                                height: compact ? 138 : 170,
                                child: Image.asset(
                                  'assets/images/bomi/bomi_dashboard_hero.png',
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 8 : 12),

                        // 주요 기능은 하나의 흰 패널 안에 묶어서 정돈한다.
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            14,
                            compact ? 13 : 16,
                            14,
                            compact ? 13 : 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x141E3A8A),
                                blurRadius: 22,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LayoutBuilder(
                                builder: (context, menuConstraints) {
                                  const spacing = 8.0;

                                  final itemWidth =
                                      (menuConstraints.maxWidth -
                                          spacing * (menuColumns - 1)) /
                                      menuColumns;

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: [
                                      for (final item in menuItems)
                                        SizedBox(
                                          width: itemWidth,
                                          child: _DashboardMenuButton(
                                            icon: item.$1,
                                            label: item.$2,
                                            onTap: () => open(context, item.$2),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (patientLinked == false &&
                            reservationRepository != null) ...[
                          Material(
                            color: AppColors.softPink,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => openService(context, 'link'),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link_rounded,
                                      size: 20,
                                      color: AppColors.navy,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '연결된 병원 기록이 없습니다.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.navy,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        _UpcomingReservationCard(
                          repository: reservationRepository,
                          compact: compact,
                          onOpenList: () => openReservations(context),
                          onCreate: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => ReservationScreen(
                                repository: reservationRepository,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 건강관리 배너 전체를 터치 영역으로 사용한다.
                        Semantics(
                          button: true,
                          label: '보미와 함께하는 더 건강한 내일. 언제나, 당신의 건강한 하루를 응원해요.',
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => openHealthManagement(context),
                              child: SizedBox(
                                height: compact ? 110 : 125,
                                width: double.infinity,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      'assets/images/bomi/bomi_home_banner.png',
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      excludeFromSemantics: true,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        16,
                                        150,
                                        14,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '보미와 함께하는',
                                            style: TextStyle(
                                              color: AppColors.blue,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            '더 건강한 내일',
                                            style: TextStyle(
                                              color: AppColors.navy,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '언제나, 당신의 건강한 하루를 응원해요.',
                                            maxLines: 2,
                                            style: TextStyle(
                                              color: AppColors.mutedText,
                                              fontSize: 10,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    bottomNavigationBar: embedded
        ? null
        : NavigationBar(
            backgroundColor: Colors.white,
            indicatorColor: AppColors.lightBlue,
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ReservationListScreen(
                      repository: reservationRepository,
                    ),
                  ),
                );
                return;
              }
              if (index == 2) {
                openHealthManagement(context);
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

class _TextScaleButton extends StatelessWidget {
  const _TextScaleButton();

  // 현재 크기에 따라 다음 글씨 크기로 순환한다.
  double _nextScale(double current) {
    if (current < 1.1) return 1.2;
    if (current < 1.35) return 1.5;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppPreferences.instance;
    final percent = (settings.textScale * 100).round();

    Future<void> changeTextScale() async {
      final nextScale = _nextScale(settings.textScale);

      await settings.save(textScale: nextScale);

      if (!context.mounted) return;

      // 변경된 글씨 크기를 짧게 안내한다.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 900),
            content: Text('글씨 크기 ${(nextScale * 100).round()}%'),
          ),
        );
    }

    return Semantics(
      button: true,
      label: '글씨 크기 $percent%',
      hint: '누르면 글씨 크기가 변경됩니다.',
      child: Tooltip(
        message: '글씨 크기 $percent%',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: changeTextScale,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '가',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 1),
                Icon(Icons.zoom_in_rounded, color: AppColors.navy, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingReservationCard extends StatefulWidget {
  const _UpcomingReservationCard({
    required this.repository,
    required this.compact,
    required this.onOpenList,
    required this.onCreate,
  });

  final ReservationRepository? repository;
  final bool compact;
  final Future<void> Function() onOpenList;
  final Future<void> Function() onCreate;

  @override
  State<_UpcomingReservationCard> createState() =>
      _UpcomingReservationCardState();
}

class _UpcomingReservationCardState extends State<_UpcomingReservationCard> {
  Future<List<PatientReservation>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _UpcomingReservationCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.repository != widget.repository) {
      _load();
    }
  }

  void _load() {
    _future = widget.repository?.getReservations();
  }

  Future<void> _runAndReload(Future<void> Function() action) async {
    await action();

    if (!mounted) return;

    setState(_load);
  }

  PatientReservation? _nextReservation(List<PatientReservation> items) {
    final now = DateTime.now();

    final upcoming = items.where((item) => !item.isPast(now)).toList()
      ..sort((a, b) => a.reservedAt.compareTo(b.reservedAt));

    return upcoming.isEmpty ? null : upcoming.first;
  }

  String _dDay(DateTime reservedAt) {
    final nowKorea = DateTime.now().toUtc().add(const Duration(hours: 9));

    final reservationKorea = reservedAt.toUtc().add(const Duration(hours: 9));

    final today = DateTime(nowKorea.year, nowKorea.month, nowKorea.day);

    final reservationDay = DateTime(
      reservationKorea.year,
      reservationKorea.month,
      reservationKorea.day,
    );

    final days = reservationDay.difference(today).inDays;

    return days <= 0 ? 'D-DAY' : 'D-$days';
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5FF), Color(0xFFF5FAFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _runAndReload(widget.onOpenList),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: widget.compact ? 10 : 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: future == null
                      ? const _ReservationSummary(subtitle: '예약 정보를 확인할 수 없어요.')
                      : FutureBuilder<List<PatientReservation>>(
                          future: future,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const _ReservationSummary(
                                subtitle: '예약 정보를 확인하고 있어요.',
                              );
                            }

                            if (snapshot.hasError) {
                              return const _ReservationSummary(
                                subtitle: '예약 정보를 불러오지 못했어요.',
                              );
                            }

                            final reservation = _nextReservation(
                              snapshot.data ?? const [],
                            );

                            if (reservation == null) {
                              return const _ReservationSummary(
                                subtitle: '예정된 진료가 없어요.',
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: _ReservationSummary(
                                    subtitle: reservation.dateLabel,
                                    status: reservation.statusLabel,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _dDay(reservation.reservedAt),
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '새 진료 예약',
                  onPressed: () => _runAndReload(widget.onCreate),
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    color: AppColors.blue,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationSummary extends StatelessWidget {
  const _ReservationSummary({required this.subtitle, this.status});

  final String subtitle;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '다가오는 진료',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (status != null) ...[
          const SizedBox(height: 2),
          Text(
            status!,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _DashboardMenuButton extends StatelessWidget {
  const _DashboardMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  Color get _accent => switch (label) {
    'AI 결과' => const Color(0xFFE76587),
    '처방 조회' => const Color(0xFF6557D9),
    '주변 약국' => const Color(0xFFD94F86),
    '리워드' => const Color(0xFFF39A3C),
    _ => AppColors.blue,
  };

  Color get _soft => switch (label) {
    'AI 결과' => const Color(0xFFFFEFF4),
    '처방 조회' => const Color(0xFFF2F0FF),
    '주변 약국' => const Color(0xFFFFEFF5),
    '리워드' => const Color(0xFFFFF5E8),
    _ => const Color(0xFFEDF6FF),
  };

  @override
  Widget build(BuildContext context) {
    // 큰 흰 패널 안에서는 별도 카드 없이 아이콘과 이름만 표시한다.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _soft, shape: BoxShape.circle),
                child: Icon(icon, size: 23, color: _accent),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
