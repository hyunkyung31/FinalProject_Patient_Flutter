import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_preferences.dart';
import '../../chatbot/widgets/chatbot_overlay_host.dart';
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
  var _selectedIndex = 2;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _pageFor(int index) {
    final repository = widget.reservationRepository;

    switch (index) {
      case 0:
        return ReservationListScreen(repository: repository, embedded: true);

      case 1:
        if (widget.patientLinked == true && repository != null) {
          return LabResultListScreen(
            repository: PatientLabResultRepository(repository.client),
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

      case 2:
        return _DashboardHome(
          reservationRepository: repository,
          onLogout: widget.onLogout,
          patientLinked: widget.patientLinked,
          patientName: widget.patientName,
          onRefreshLink: widget.onRefreshLink,
          embedded: true,
          onSelectTab: _selectTab,
        );

      case 3:
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

      case 4:
        if (repository != null) {
          return PatientServicesScreen(
            repository: repository,
            section: 'settings',
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
            tinted: _selectedIndex == 2,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(5, _pageFor),
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '예약',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: '검사결과',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: '건강관리',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '설정',
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
              IconButton(
                tooltip: '보미 챗봇',
                onPressed: ChatbotOverlayController.instance.open,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({
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
      onSelectTab!(3);
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

  void openLabResults(BuildContext context) {
    if (embedded && onSelectTab != null) {
      onSelectTab!(1);
      return;
    }

    open(context, '검사결과');
  }

  Future<void> openReservations(BuildContext context) async {
    if (embedded && onSelectTab != null) {
      onSelectTab!(0);
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
    backgroundColor: const Color(0xFFF4F6FB),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final largeText = textScale >= 1.2;
            final compact = constraints.maxHeight < 700 && !largeText;
            final menuColumns = largeText || constraints.maxWidth < 360 ? 2 : 4;

            final menuItems = <(IconData, String, String, String)>[
              (Icons.table_chart_outlined, '검사결과', '내 검사 결과\n확인', '검사결과'),
              (Icons.description_outlined, '리포트', 'AI 건강 리포트', '리포트'),
              (Icons.medication_outlined, '처방조회', '내 처방 내역', '처방 조회'),
              (Icons.home_work_outlined, '주변 약국', '가까운 약국 찾기', '주변 약국'),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단 인사말부터 예약 카드까지 하나의 부드러운 배경으로 연결한다.
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      embedded ? 8 : MediaQuery.paddingOf(context).top + 8,
                      20,
                      16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE8EEFF), Color(0xFFF0F2FB)],
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
                                height: 30,
                                fit: BoxFit.contain,
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
                                ),
                            ],
                          ),

                        SizedBox(
                          height: textScale >= 1.45
                              ? 190
                              : (largeText ? 158 : (compact ? 112 : 132)),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: compact ? 10 : 14,
                                    right: textScale >= 1.45
                                        ? 108
                                        : (compact ? 122 : 152),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patientName?.trim().isNotEmpty == true
                                            ? '안녕하세요,\n${patientName!.trim()}님!'
                                            : '안녕하세요!',
                                        maxLines: 2,
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: compact ? 25 : 28,
                                          height: 1.08,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '오늘도 보미와 건강한 하루 함께해요.',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF7385B7),
                                          fontSize: 12,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: compact ? -4 : 0,
                                bottom: -18,
                                child: SizedBox(
                                  width: textScale >= 1.45
                                      ? 128
                                      : (compact ? 140 : 170),
                                  height: textScale >= 1.45
                                      ? 140
                                      : (compact ? 145 : 176),
                                  child: Image.asset(
                                    'assets/images/bomi/bomi_dashboard_hero.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomRight,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

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
                      ],
                    ),
                  ),

                  Container(
                    color: const Color(0xFFF4F6FB),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
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

                        // 자주 사용하는 4개 기능을 독립 카드로 배치한다.
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
                                      subtitle: item.$3,
                                      onTap: () {
                                        if (item.$4 == '검사결과') {
                                          openLabResults(context);
                                          return;
                                        }

                                        open(context, item.$4);
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        _HomeStudioCard(onTap: () => open(context, '보미 스튜디오')),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _HomeSmallPromoCard(
                                eyebrow: '이번 주도 꾸준히!',
                                title: '건강관리',
                                description: '오늘의 건강 미션을 확인해요.',
                                buttonLabel: '지금 시작하기',
                                backgroundColor: const Color(0xFFDDEEFF),
                                foregroundColor: AppColors.navy,
                                buttonColor: AppColors.blue,
                                assetPath:
                                    'assets/images/bomi/bomi_health_icon.png',
                                onTap: () => openHealthManagement(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HomeSmallPromoCard(
                                eyebrow: '건강할수록 커지는',
                                title: '두근 리워드',
                                description: '포인트로 더 특별한 혜택을 받아보세요!',
                                buttonLabel: '내 리워드 보기',
                                backgroundColor: const Color(0xFFFFF0BF),
                                foregroundColor: AppColors.navy,
                                buttonColor: const Color(0xFFE89A24),
                                assetPath:
                                    'assets/images/bomi/bomi_reward_icon.png',
                                onTap: () => open(context, '리워드'),
                              ),
                            ),
                          ],
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

    // 단독 화면으로 실행되는 개발/데모 환경도 기존 이동 동작을 유지한다.
    bottomNavigationBar: embedded
        ? null
        : NavigationBar(
            backgroundColor: Colors.white,
            indicatorColor: AppColors.lightBlue,
            selectedIndex: 2,
            onDestinationSelected: (index) {
              if (index == 0) {
                openReservations(context);
                return;
              }
              if (index == 1) {
                openLabResults(context);
                return;
              }
              if (index == 3) {
                openHealthManagement(context);
                return;
              }
              if (index == 4 && reservationRepository != null) {
                openService(context, 'settings');
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                label: '예약',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                label: '검사결과',
              ),
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.navy),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                label: '건강관리',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                label: '설정',
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
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  Color get _accent => switch (label) {
    '리포트' => const Color(0xFF5573D9),
    '처방조회' => const Color(0xFF9A63E8),
    '주변 약국' => const Color(0xFFFF7043),
    _ => const Color(0xFF4E73DF),
  };

  Color get _soft => switch (label) {
    '리포트' => const Color(0xFFEAF0FF),
    '처방조회' => const Color(0xFFF2EAFF),
    '주변 약국' => const Color(0xFFFFEEE8),
    _ => const Color(0xFFEAF0FF),
  };

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: textScale >= 1.45 ? 158 : 132),
          padding: const EdgeInsets.fromLTRB(6, 16, 6, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9ECF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A1E3A8A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _soft, shape: BoxShape.circle),
                child: Icon(icon, size: 23, color: _accent),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7D89AA),
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeStudioCard extends StatelessWidget {
  const _HomeStudioCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardHeight = textScale >= 1.45
        ? 222.0
        : (textScale >= 1.2 ? 198.0 : 148.0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE4EC), Color(0xFFFFABC3), Color(0xFFE6D9FF)],
            stops: [0.0, 0.56, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1FD64E79),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: cardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -38,
                  top: -52,
                  child: Container(
                    width: 145,
                    height: 145,
                    decoration: const BoxDecoration(
                      color: Color(0x42FFFFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: 138,
                  bottom: -82,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: const BoxDecoration(
                      color: Color(0x20FFFFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Positioned(
                  right: 132,
                  top: 20,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xE6FFFFFF),
                    size: 22,
                  ),
                ),
                const Positioned(
                  right: 116,
                  top: 49,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0x8CFFFFFF),
                    size: 13,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: SizedBox(
                    width: textScale >= 1.45 ? 126 : 154,
                    height: textScale >= 1.45 ? 138 : 160,
                    child: Image.asset(
                      'assets/images/bomi/bomi_heart_banner.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    19,
                    textScale >= 1.45 ? 106 : 138,
                    18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '나만의 작은 친구,',
                        style: TextStyle(
                          color: Color(0xFFE44268),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '보미 스튜디오',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 22,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        '보미를 꾸미고 새로운 아이템을 만나보세요!',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF85546C),
                          fontSize: 11,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF14669), Color(0xFFE74C8A)],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x30E84770),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '지금 꾸미러 가기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ],
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
    );
  }
}

class _HomeSmallPromoCard extends StatelessWidget {
  const _HomeSmallPromoCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.buttonColor,
    required this.assetPath,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String buttonLabel;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color buttonColor;
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactHome = textScale < 1.2;
    final cardHeight = textScale >= 1.45
        ? 220.0
        : (textScale >= 1.2 ? 188.0 : 112.0);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: cardHeight,
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: SizedBox(
                  width: compactHome ? 64 : 92,
                  height: compactHome ? 64 : 92,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compactHome ? 12 : 15,
                  compactHome ? 8 : 15,
                  10,
                  compactHome ? 7 : 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      maxLines: 1,
                      style: TextStyle(
                        color: buttonColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: compactHome ? 15 : 17,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: compactHome ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF66738F),
                        fontSize: compactHome ? 8 : 9,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 112),
                      padding: EdgeInsets.symmetric(
                        horizontal: compactHome ? 8 : 11,
                        vertical: compactHome ? 4 : 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: buttonColor),
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              buttonLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: buttonColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: buttonColor,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
