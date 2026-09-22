import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_preferences.dart';
import '../../chatbot/widgets/chatbot_overlay_host.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../onboarding/view/home_feature_tour_overlay.dart';
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
import '../../bomi_studio/repository/bomi_studio_repository.dart';
import '../../bomi_studio/view/bomi_studio_screen.dart';
import '../../prescription/repository/patient_prescription_repository.dart';
import '../../prescription/view/patient_prescription_list_screen.dart';
import '../../patient_report/repository/patient_report_repository.dart';
import '../../patient_report/view/patient_report_list_screen.dart';
import 'patient_result_hub_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.reservationRepository,
    this.onLogout,
    this.patientLinked,
    this.patientName,
    this.onRefreshLink,
    this.startFeatureTour = false,
    this.onFeatureTourFinished,
  });

  final bool? patientLinked;
  final String? patientName;
  final Future<void> Function()? onRefreshLink;
  final Future<void> Function()? onLogout;
  final bool startFeatureTour;
  final Future<void> Function()? onFeatureTourFinished;
  final ReservationRepository? reservationRepository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _selectedIndex = 2;
  bool _showPrescription = false;
  final _reservationKey = GlobalKey();
  final _quickMenuKey = GlobalKey();
  final _chatbotKey = GlobalKey();
  final _healthTabKey = GlobalKey();
  OverlayEntry? _featureTourOverlay;
  bool _showingFeatureTour = false;

  @override
  void initState() {
    super.initState();
    if (widget.startFeatureTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFeatureTour());
    }
  }

  void _showFeatureTour() {
    if (!mounted || _showingFeatureTour) return;
    if (_reservationKey.currentContext == null ||
        _quickMenuKey.currentContext == null ||
        _chatbotKey.currentContext == null ||
        _healthTabKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFeatureTour());
      return;
    }

    _showingFeatureTour = true;
    _featureTourOverlay = OverlayEntry(
      builder: (_) => HomeFeatureTourOverlay(
        reservationKey: _reservationKey,
        quickMenuKey: _quickMenuKey,
        chatbotKey: _chatbotKey,
        healthTabKey: _healthTabKey,
        onFinish: _finishFeatureTour,
        onSkip: _skipFeatureTour,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_featureTourOverlay!);
  }

  void _dismissFeatureTour() {
    _featureTourOverlay?.remove();
    _featureTourOverlay = null;
    _showingFeatureTour = false;
  }

  Future<void> _finishFeatureTour() async {
    _dismissFeatureTour();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) await showHomeTourTextScalePicker(context);
    await widget.onFeatureTourFinished?.call();
  }

  Future<void> _skipFeatureTour() async {
    _dismissFeatureTour();
    await widget.onFeatureTourFinished?.call();
  }

  @override
  void dispose() {
    _dismissFeatureTour();
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _showPrescription = false;
    });
  }

  Widget _pageFor(int index) {
    final repository = widget.reservationRepository;

    switch (index) {
      case 0:
        return ReservationListScreen(repository: repository, embedded: true);

      case 1:
        if (widget.patientLinked == true && repository != null) {
          return PatientResultHubScreen(repository: repository);
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
        if (_showPrescription &&
            widget.patientLinked == true &&
            repository != null) {
          return PatientPrescriptionListScreen(
            repository: PatientPrescriptionRepository(repository.client),
            embedded: true,
          );
        }

        return _DashboardHome(
          reservationRepository: repository,
          onLogout: widget.onLogout,
          patientLinked: widget.patientLinked,
          patientName: widget.patientName,
          onRefreshLink: widget.onRefreshLink,
          reservationKey: _reservationKey,
          quickMenuKey: _quickMenuKey,
          embedded: true,
          onSelectTab: _selectTab,
          onOpenPrescription: () {
            setState(() {
              _showPrescription = true;
            });
          },
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
            onLogout: widget.onLogout,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _PersistentTopBar(
            repository: widget.reservationRepository,
            tinted: _selectedIndex == 2,
            onShowGuide: _showFeatureTour,
            chatbotKey: _chatbotKey,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: [
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
            key: _healthTabKey,
            icon: const Icon(Icons.favorite_border_rounded),
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
  const _PersistentTopBar({
    required this.repository,
    required this.tinted,
    required this.onShowGuide,
    required this.chatbotKey,
  });

  final ReservationRepository? repository;
  final bool tinted;
  final VoidCallback onShowGuide;
  final GlobalKey chatbotKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: tinted
                ? LinearGradient(
                    colors: dark
                        ? const [Color(0xFF17294A), Color(0xFF202A4B)]
                        : const [Color(0xFFE8EEFF), Color(0xFFF0F2FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: tinted ? null : scheme.surface,
            border: tinted
                ? null
                : Border(bottom: BorderSide(color: scheme.outlineVariant)),
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
                onPressed: onShowGuide,
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: dark ? scheme.onSurface : AppColors.navy,
                ),
              ),
              if (repository != null)
                PatientNotificationButton(repository: repository!)
              else
                const SizedBox(width: 48),
              IconButton(
                key: chatbotKey,
                tooltip: '\uBCF4\uBBF8 \uCC57\uBD07',
                onPressed: ChatbotOverlayController.instance.open,
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: dark ? scheme.onSurface : AppColors.navy,
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
    this.reservationKey,
    this.quickMenuKey,
    this.embedded = false,
    this.onSelectTab,
    this.onOpenPrescription,
  });
  final bool? patientLinked;
  final String? patientName;
  final Future<void> Function()? onRefreshLink;
  final Future<void> Function()? onLogout;
  final GlobalKey? reservationKey;
  final GlobalKey? quickMenuKey;
  final ReservationRepository? reservationRepository;
  final bool embedded;
  final ValueChanged<int>? onSelectTab;
  final VoidCallback? onOpenPrescription;
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
    if (title == '처방 조회' &&
        embedded &&
        onOpenPrescription != null &&
        patientLinked == true &&
        reservationRepository != null) {
      onOpenPrescription!();
      return;
    }

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
        '검사결과' => PatientResultHubScreen(repository: repository),
        '리포트' => PatientReportListScreen(
          repository: PatientReportRepository(repository.client),
        ),
        '처방 조회' => PatientPrescriptionListScreen(
          repository: PatientPrescriptionRepository(repository.client),
        ),
        '보미 스튜디오' => BomiStudioScreen(
          repository: PatientRewardRepository(repository.client),
          equipmentRepository: PatientBomiStudioRepository(repository.client),
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
                        ['검사결과', '리포트', '처방 조회', '리워드', '건강관리'].contains(title)
                    ? '병원기록 연결 후 확인할 수 있어요. 조회 화면은 준비 중이에요.'
                    : '이 기능은 준비 중이에요.',
              ),
              if (patientLinked == false &&
                  reservationRepository != null &&
                  ['검사결과', '리포트', '처방 조회', '리워드', '건강관리'].contains(title))
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
              (Icons.description_outlined, '리포트', '내 리포트 확인', '리포트'),
              (Icons.medication_outlined, '처방조회', '내 처방 내역', '처방 조회'),
              (Icons.home_work_outlined, '주변 약국', '가까운 약국 찾기', '주변 약국'),
            ];

            return SingleChildScrollView(
              key: quickMenuKey,
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
                                      Text(
                                        '오늘도 보미와 건강한 하루 함께해요.',
                                        maxLines: textScale >= 1.2 ? 2 : 1,
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
                                right: 4,
                                bottom: -14,
                                child: SizedBox(
                                  width: 145,
                                  height: 150,
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
                          key: reservationKey,
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
                        Text(
                          '내 건강을 위한 주요 서비스',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '검사부터 처방까지, 더 건강한 오늘을 위해',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF73809A),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Keep the four core medical services at equal size.
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

                        _HomeHealthCard(
                          onTap: () => openHealthManagement(context),
                        ),

                        const SizedBox(height: 12),

                        _HomeHealthInfoSection(),
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
    super.key,
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale >= 1.2;

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
          maxLines: largeText ? 2 : 1,
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

class _HomeHealthCard extends StatelessWidget {
  const _HomeHealthCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactHome = textScale < 1.2;
    final cardHeight = textScale >= 1.45
        ? 148.0
        : (textScale >= 1.2 ? 128.0 : 98.0);

    return Material(
      color: const Color(0xFFDDEEFF),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: cardHeight,
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -54,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -6,
                bottom: -10,
                child: SizedBox(
                  width: compactHome ? 88 : 102,
                  height: compactHome ? 88 : 102,
                  child: Image.asset(
                    'assets/images/bomi/bomi_health_icon.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, compactHome ? 82 : 94, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이번 주도 꾸준히!',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Text(
                          '건강관리',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 18,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.blue),
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(alpha: 0.42),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '지금 시작하기',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.blue,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '오늘의 건강 미션을 확인해요.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF66738F),
                        fontSize: 10,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
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

class _DailyHealthGuide {
  const _DailyHealthGuide({
    required this.title,
    required this.description,
    required this.items,
    required this.referenceTitle,
    required this.referenceUrl,
  });

  final String title;
  final String description;
  final List<String> items;
  final String referenceTitle;
  final String referenceUrl;
}

const _dailyHealthGuides = <_DailyHealthGuide>[
  _DailyHealthGuide(
    title: '혈압, 정확하게 측정하려면?',
    description: '가정에서도 같은 조건과 올바른 자세로 측정하는 것이 중요해요.',
    items: [
      '측정 전 약 5분간 편안하게 앉아 쉬어요.',
      '등을 기대고 두 발을 바닥에 편안히 두어요.',
      '팔을 심장 높이에 두고 커프를 알맞게 착용해요.',
      '측정 중에는 말하지 않고 편안히 있어요.',
    ],
    referenceTitle: '고혈압',
    referenceUrl:
        'https://health.kdca.go.kr/healthinfo/biz/health/gnrlzHealthInfo/gnrlzHealthInfo/gnrlzHealthInfoView.do?cntnts_sn=6765',
  ),
  _DailyHealthGuide(
    title: '나트륨, 일상에서 어떻게 줄일까요?',
    description: '국·찌개와 가공식품에서 나트륨 섭취가 늘어날 수 있어요.',
    items: [
      '국과 찌개는 국물을 덜 먹는 습관을 실천해보세요.',
      '가공식품은 영양성분표의 나트륨 함량을 확인해요.',
      '양념과 소스는 필요한 만큼만 사용해요.',
      '외식할 때도 짜지 않은 메뉴를 선택해보세요.',
    ],
    referenceTitle: '건강하게 염분 섭취하는 방법! 알려드리겠습니다!',
    referenceUrl:
        'https://health.kdca.go.kr/healthinfo/biz/health/gnrlzHealthInfo/gnrlzHealthInfo/gnrlzHealthInfoView.do?cntnts_sn=5335',
  ),
  _DailyHealthGuide(
    title: '운동 전후 5~10분, 왜 필요할까요?',
    description: '준비운동과 정리운동은 안전하게 운동하는 데 도움이 돼요.',
    items: [
      '본 운동 전 5~10분 가볍게 몸을 풀어요.',
      '운동 강도는 자신의 체력과 건강상태에 맞춰요.',
      '운동 후에도 5~10분 천천히 몸을 정리해요.',
      '무리한 운동보다 꾸준한 실천이 중요해요.',
    ],
    referenceTitle: '운동',
    referenceUrl:
        'https://health.kdca.go.kr/healthinfo/biz/health/gnrlzHealthInfo/gnrlzHealthInfo/gnrlzHealthInfoView.do?cntnts_sn=5293',
  ),
  _DailyHealthGuide(
    title: '영양성분표, 무엇부터 볼까요?',
    description: '포장지의 강조 문구보다 실제 영양성분 함량을 확인해보세요.',
    items: [
      '먼저 1회 제공량과 총 내용량을 확인해요.',
      '1일 영양성분 기준치(%)도 같이 보세요.',
      '나트륨·당류·포화지방 함량을 비교해보세요.',
      '\'무지방\', \'저당\' 같은 문구만 보지 말고 성분표를 확인해요.',
    ],
    referenceTitle: '영양표시 읽는 법! 알려드리겠습니다!',
    referenceUrl:
        'https://health.kdca.go.kr/healthinfo/biz/health/gnrlzHealthInfo/gnrlzHealthInfo/gnrlzHealthInfoView.do?cntnts_sn=6763',
  ),
  _DailyHealthGuide(
    title: '건강한 식사, 무엇을 줄이고 채울까요?',
    description: '열량만 줄이기보다 영양의 질을 같이 살펴보세요.',
    items: [
      '당이 많은 음료와 과자·디저트는 줄여보세요.',
      '짠 가공식품과 국·찌개 국물 섭취를 줄여요.',
      '채소와 통곡물 등 식이섬유를 챙겨요.',
      '생선·견과류 등 불포화지방이 포함된 식품을 활용해요.',
    ],
    referenceTitle: '건강한 체중조절을 위한 식사',
    referenceUrl:
        'https://health.kdca.go.kr/healthinfo/biz/health/gnrlzHealthInfo/gnrlzHealthInfo/gnrlzHealthInfoView.do?cntnts_sn=6547',
  ),
  _DailyHealthGuide(
    title: '심뇌혈관 건강, 지금부터 살펴보세요',
    description: '고혈압·당뇨병·이상지질혈증 같은 위험요인을 조기에 알고 관리하는 것이 중요해요.',
    items: [
      '자신의 혈압·혈당·콜레스테롤 수치를 정기적으로 확인해요.',
      '일상에서 꾸준히 움직이고 운동하는 습관을 만들어요.',
      '짜고 달고 지방이 많은 식사를 줄여보세요.',
      '건강검진 결과에서 이상이 있다면 필요한 진료를 받아요.',
    ],
    referenceTitle: '20대부터 시작하는 심뇌혈관질환 예방관리',
    referenceUrl:
        'https://health.kdca.go.kr/healthinfo/biz/health/ntcnInfo/healthSourc/thtimtCntnts/thtimtCntntsView.do?thtimt_cntnts_sn=176',
  ),
  _DailyHealthGuide(
    title: '금연, 시작하는 순간부터 건강에 도움이 돼요',
    description: '담배를 끊으면 건강은 바로 좋아지기 시작하며, 필요하면 상담과 전문적인 도움을 받을 수 있어요.',
    items: [
      '흡연과 간접흡연은 심혈관계를 포함한 건강에 해로울 수 있어요.',
      '금연이 어렵다면 혼자 견디기보다 전문가의 상담과 도움을 활용해보세요.',
      '보건소 금연클리닉과 금연상담전화 등 공공 지원서비스도 이용할 수 있어요.',
      '전자담배도 안전한 금연 대체수단으로 보지 않는 것이 좋아요.',
    ],
    referenceTitle: '흡연',
    referenceUrl:
        'https://health.kdca.go.kr/healthinfo/biz/health/gnrlzHealthInfo/gnrlzHealthInfo/gnrlzHealthInfoView.do?cntnts_sn=6764',
  ),
];

_DailyHealthGuide _dailyHealthGuideFor(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final firstDay = DateTime(now.year, 1, 1);
  final dayIndex = today.difference(firstDay).inDays;

  return _dailyHealthGuides[dayIndex % _dailyHealthGuides.length];
}

class _HomeHealthInfoSection extends StatelessWidget {
  const _HomeHealthInfoSection();

  @override
  Widget build(BuildContext context) {
    final guide = _dailyHealthGuideFor(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '건강 안내',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4E9F3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _HomeHealthInfoRow(
                icon: Icons.event_note_rounded,
                iconBackground: Color(0xFFEAF1FF),
                iconColor: AppColors.blue,
                title: '진료·검사 준비 안내',
                subtitle: '병원 안내와 준비사항을 미리 확인해요.',
                onTap: () => _showPreparationGuide(context),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 62),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEF1F6),
                ),
              ),
              _HomeHealthInfoRow(
                icon: Icons.favorite_outline_rounded,
                iconBackground: Color(0xFFFFF0F3),
                iconColor: Color(0xFFE15C78),
                title: '오늘의 건강 가이드',
                subtitle: guide.title,
                onTap: () => _showHealthGuide(context, guide),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeHealthInfoRow extends StatelessWidget {
  const _HomeHealthInfoRow({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A879F),
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: Color(0xFFA5AFC1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showPreparationGuide(BuildContext context) {
  _showHealthInfoSheet(
    context,
    icon: Icons.event_note_rounded,
    title: '진료·검사 준비 안내',
    description: '방문 전 병원에서 안내받은 내용을 가장 먼저 확인해주세요.',
    items: const [
      '예약 시간과 방문 장소를 다시 확인해요.',
      '금식이나 약 복용 안내를 받았다면 병원의 지시를 우선해요.',
      '복용 중인 약과 알레르기 정보가 있다면 의료진에게 알려주세요.',
      '이전 검사 결과나 진료 기록이 필요한지 미리 확인해요.',
    ],
  );
}

void _showHealthGuide(BuildContext context, _DailyHealthGuide guide) {
  _showHealthInfoSheet(
    context,
    icon: Icons.favorite_outline_rounded,
    title: guide.title,
    description: guide.description,
    items: guide.items,
    referenceTitle: guide.referenceTitle,
    referenceUrl: guide.referenceUrl,
  );
}

Future<void> _openHealthReference(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('참고 페이지를 열 수 없어요.')));
  }
}

void _showHealthInfoSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String description,
  required List<String> items,
  String? referenceTitle,
  String? referenceUrl,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.blue, size: 23),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF66738F),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              for (final item in items) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF1FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 12.5,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
              ],
              if (referenceTitle != null && referenceUrl != null) ...[
                const SizedBox(height: 2),
                const Text(
                  '참고',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Material(
                  color: const Color(0xFFF7F9FD),
                  borderRadius: BorderRadius.circular(13),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        _openHealthReference(sheetContext, referenceUrl),
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 20,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '질병관리청 국가건강정보포털',
                                  style: TextStyle(
                                    color: Color(0xFF74819A),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  referenceTitle,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 11.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: AppColors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Text(
                  '개인별 진료·검사 지시가 있는 경우 해당 의료진의 안내를 우선해주세요.',
                  style: TextStyle(
                    color: Color(0xFF6E7A92),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
