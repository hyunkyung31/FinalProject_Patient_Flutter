import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/health_mission.dart';
import '../repository/health_mission_repository.dart';
import '../../reward/repository/reward_repository.dart';
import '../../reward/view/reward_screen.dart';
import 'health_mission_detail_screen.dart';
import 'health_checkin_screen.dart';
import 'health_activity_section.dart';
import 'health_quiz_screen.dart';
import 'health_bingo_screen.dart';
import 'health_walk_screen.dart';

class HealthManagementScreen extends StatefulWidget {
  const HealthManagementScreen({
    super.key,
    required this.repository,
    this.checkInScreenBuilder,
    this.conceptSection,
    this.rewardRepository,
    this.onOpenBomiStudio,
    this.embedded = false,
  });

  final HealthMissionRepository repository;
  final WidgetBuilder? checkInScreenBuilder;
  final Widget? conceptSection;
  final RewardRepository? rewardRepository;
  final VoidCallback? onOpenBomiStudio;
  final bool embedded;

  @override
  State<HealthManagementScreen> createState() => _HealthManagementScreenState();
}

class _HealthManagementScreenState extends State<HealthManagementScreen> {
  List<PatientHealthMission> _missions = const [];
  bool _loading = true;
  String? _error;
  int? _pointBalance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final missions = await widget.repository.getTodayMissions();

      if (!mounted) return;

      setState(() {
        _missions = missions;
        _loading = false;
      });

      await _refreshPointBalance();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = healthMissionErrorMessage(error);
      });
    }
  }

  // 오늘의 DAILY_CHECKIN 미션을 찾아 체크인 화면과 실제 보상 API를 연결한다.
  // 리워드 조회 실패가 건강 미션 화면 전체 실패로 이어지지 않게 분리한다.
  Future<void> _refreshPointBalance() async {
    final repository = widget.rewardRepository;

    if (repository == null) {
      if (!mounted) return;

      setState(() {
        _pointBalance = null;
      });
      return;
    }

    try {
      final account = await repository.getPointAccount();

      if (!mounted) return;

      setState(() {
        _pointBalance = account.balance;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _pointBalance = null;
      });
    }
  }

  Future<void> _openCheckIn() async {
    PatientHealthMission? checkInMission;
    PatientHealthMission? breathMission;

    for (final mission in _missions) {
      final code = mission.healthMission.code.trim().toUpperCase();

      if (code == 'DAILY_CHECKIN') {
        checkInMission = mission;
      } else if (code == 'DAILY_BREATH') {
        breathMission = mission;
      }

      if (checkInMission != null && breathMission != null) {
        break;
      }
    }

    if (checkInMission == null) {
      final previewBuilder = widget.checkInScreenBuilder;

      if (previewBuilder != null) {
        await Navigator.of(
          context,
        ).push<void>(MaterialPageRoute(builder: previewBuilder));
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘의 체크인 미션을 준비 중이에요.')));
      return;
    }

    if (breathMission == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘의 1분 호흡 미션을 준비 중이에요.')));
      return;
    }

    if (checkInMission.isCompleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘 체크인은 이미 완료했어요.')));
      return;
    }

    final checkInResult = await Navigator.of(context).push<HealthCheckInResult>(
      MaterialPageRoute(
        builder: (_) => HealthCheckInScreen(
          repository: widget.repository,
          mission: checkInMission!,
          breathMission: breathMission!,
        ),
      ),
    );

    if (checkInResult == null || !mounted) return;

    // 체크인 완료 후 미션과 실제 서버 포인트 잔액을 다시 조회한다.
    await _load();

    if (!mounted) return;

    if (checkInResult.alreadyCompleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘 체크인은 이미 처리됐어요.')));
      return;
    }

    final awardedPoints = checkInResult.awardedPoints;

    if (awardedPoints == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('체크인은 완료됐지만 새로 적립된 포인트 내역은 확인되지 않았어요.')),
      );
      return;
    }

    final pointText = awardedPoints == awardedPoints.roundToDouble()
        ? awardedPoints.toInt().toString()
        : awardedPoints.toStringAsFixed(1);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('체크인 완료! +${pointText}P가 적립됐어요.')));
  }

  Future<void> _openMission(PatientHealthMission mission) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HealthMissionDetailScreen(
          repository: widget.repository,
          mission: mission,
        ),
      ),
    );

    if (changed == true) {
      await _load();
    }
  }

  // 오늘 배정된 DAILY_WALK 미션과 Health Connect 걸음 기록을 연결한다.
  Future<void> _openWalk() async {
    PatientHealthMission? walkMission;

    for (final mission in _missions) {
      if (mission.healthMission.code.trim().toUpperCase() == 'DAILY_WALK') {
        walkMission = mission;
        break;
      }
    }

    if (walkMission == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘의 리듬산책 미션을 준비 중이에요.')));
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HealthWalkScreen(
          repository: widget.repository,
          mission: walkMission!,
        ),
      ),
    );

    if (!mounted) return;

    // 산책 화면에서 기록된 최신 걸음 진행도를 다시 반영한다.
    await _load();
  }

  // 오늘 배정된 DAILY_QUIZ 미션과 실제 퀴즈 API를 연결한다.
  Future<void> _openQuiz() async {
    PatientHealthMission? quizMission;

    for (final mission in _missions) {
      if (mission.healthMission.code.trim().toUpperCase() == 'DAILY_QUIZ') {
        quizMission = mission;
        break;
      }
    }

    if (quizMission == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘의 건강퀴즈 미션을 준비 중이에요.')));
      return;
    }

    final mission = quizMission;

    if (mission.isCompleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘 건강퀴즈는 이미 완료했어요.')));
      return;
    }

    final result = await Navigator.of(context).push<HealthQuizScreenResult>(
      MaterialPageRoute(
        builder: (_) =>
            HealthQuizScreen(repository: widget.repository, mission: mission),
      ),
    );

    if (result == null || !mounted) return;

    // 퀴즈 완료 후 오늘 미션과 실제 서버 포인트 잔액만 다시 조회한다.
    // 성공 안내는 퀴즈 화면의 보미 보상 팝업에서 한 번만 보여준다.
    await _load();
  }

  // 이번 주 WEEKLY_BINGO 미션과 두근빙고 화면을 연결한다.
  Future<void> _openBingo() async {
    PatientHealthMission? bingoMission;

    for (final mission in _missions) {
      if (mission.healthMission.code.trim().toUpperCase() == 'WEEKLY_BINGO') {
        bingoMission = mission;
        break;
      }
    }

    if (bingoMission == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이번 주 두근빙고 미션을 준비 중이에요.')));
      return;
    }

    final mission = bingoMission;

    // 완료된 주간 빙고도 다시 열어 완성 상태를 확인할 수 있게 한다.
    final result = await Navigator.of(context).push<HealthBingoScreenResult>(
      MaterialPageRoute(
        builder: (_) =>
            HealthBingoScreen(repository: widget.repository, mission: mission),
      ),
    );

    if (result == null || !mounted) return;

    // 빙고 수행 후 미션 진행도와 서버 포인트 잔액을 다시 조회한다.
    await _load();
  }

  // 아직 구현 전인 건강 활동은 준비 중 안내만 표시한다.
  void _showActivityPreparing(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title 기능은 준비 중이에요.')));
  }

  Future<void> _openRewards() async {
    final repository = widget.rewardRepository;

    if (repository == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => RewardScreen(repository: repository)),
    );

    if (!mounted) return;

    await _refreshPointBalance();
  }

  @override
  Widget build(BuildContext context) {
    final actionMissions = _missions.where((mission) {
      final code = mission.healthMission.code.trim().toUpperCase();

      return code != 'DAILY_CHECKIN' &&
          code != 'DAILY_QUIZ' &&
          code != 'DAILY_WALK' &&
          code != 'DAILY_BREATH' &&
          code != 'WEEKLY_BINGO';
    }).toList();

    // 오늘의 체크인 완료 여부를 홈 카드에도 동일하게 반영한다.
    var checkInCompleted = false;

    for (final mission in _missions) {
      final code = mission.healthMission.code.trim().toUpperCase();

      if (code == 'DAILY_CHECKIN') {
        checkInCompleted = mission.isCompleted;
        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                '건강관리',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _TodayCheckInCard(
              onTap: _openCheckIn,
              isCompleted: checkInCompleted,
            ),
            const SizedBox(height: 16),
            if (widget.conceptSection != null) ...[
              widget.conceptSection!,
              const SizedBox(height: 24),
            ] else ...[
              HealthActivitySection(
                onWalk: _openWalk,
                onQuiz: _openQuiz,
                onBingo: _openBingo,
                onStudio:
                    widget.onOpenBomiStudio ??
                    () => _showActivityPreparing('보미 꾸미기'),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.rewardRepository != null) ...[
              _RewardEntryCard(onTap: _openRewards, balance: _pointBalance),
              const SizedBox(height: 24),
            ],
            if (_loading)
              const _LoadingState()
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else if (actionMissions.isNotEmpty) ...[
              const Text(
                '오늘의 실천',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '오늘 실천할 수 있는 건강 활동이에요.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 14),
              ...actionMissions.map(
                (mission) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MissionCard(
                    mission: mission,
                    onTap: () => _openMission(mission),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            const _BomiEncouragementCard(),
          ],
        ),
      ),
    );
  }
}

class _RewardEntryCard extends StatelessWidget {
  const _RewardEntryCard({required this.onTap, required this.balance});

  final VoidCallback onTap;
  final int? balance;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF5F9FF), Color(0xFFFFFBFD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2EAF5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08183B70),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Image.asset(
                  'assets/images/bomi/bomi_reward_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '두근 리워드',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDF3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            balance == null ? '건강 활동 보상' : '${balance}P',
                            style: const TextStyle(
                              color: Color(0xFFF34F7D),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '건강 활동을 이어가며 보미 아이템을 해금해요.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8090A8),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCheckInCard extends StatelessWidget {
  const _TodayCheckInCard({required this.onTap, required this.isCompleted});

  final VoidCallback onTap;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 12, isCompleted ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? const [Color(0xFFFFF3F7), Color(0xFFF3F7FF)]
              : const [Color(0xFFF4F8FF), Color(0xFFFFFBFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFFFD8E5)
              : const Color(0xFFE1EAF8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A183B70),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0x55E7F0FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 54,
            bottom: -18,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0x40FFDDE8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isCompleted ? '오늘 체크인 완료' : '오늘의 두근 체크인',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEAF1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: Color(0xFFF75283),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  '완료',
                                  style: TextStyle(
                                    color: Color(0xFFF75283),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCompleted
                          ? '오늘도 건강 체크를 잘 마쳤어요.'
                          : '오늘의 몸과 마음을 가볍게 확인해요.',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 9),

                    if (isCompleted) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.air_rounded,
                                  size: 14,
                                  color: Color(0xFF4E7DDD),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '1분 숨쉬기 완료',
                                  style: TextStyle(
                                    color: Color(0xFF345CBA),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEAF1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.card_giftcard_rounded,
                                  size: 14,
                                  color: Color(0xFFF75283),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '리워드 적립',
                                  style: TextStyle(
                                    color: Color(0xFFF04D7B),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FC),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Color(0xFF7B8AA3),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '내일도 함께해요 👋',
                                style: TextStyle(
                                  color: Color(0xFF687891),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text('', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Color(0xFF6D7E99),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '약 1분이면 충분해요',
                            style: TextStyle(
                              color: Color(0xFF6D7E99),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF75283),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(160, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 7,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '체크인 시작',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 17),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: isCompleted ? 108 : 132,
                height: isCompleted ? 112 : 138,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/bomi/bomi_health_checkin.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (isCompleted) ...[
                      const Positioned(
                        top: 2,
                        right: 10,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 19,
                          color: Color(0xFFFFC84A),
                        ),
                      ),
                      const Positioned(
                        top: 29,
                        left: 6,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: Color(0xFFF58AA8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.onTap});

  final PatientHealthMission mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseMission = mission.healthMission;
    final target = baseMission.targetValue;
    final percent = mission.progressPercent;
    final progressValue = target == null
        ? null
        : (percent ?? ((mission.progressValue / target) * 100)).clamp(0, 100);

    final completed = mission.isCompleted;
    final normalizedType = baseMission.missionType.trim().toUpperCase();

    final isHabitMission =
        normalizedType.contains('HABIT') ||
        normalizedType.contains('FOOD') ||
        normalizedType.contains('DIET') ||
        normalizedType.contains('NUTRITION');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFFFE8EF)
                      : AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _missionIcon(baseMission.missionType),
                  color: completed ? const Color(0xFFF75283) : AppColors.blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            baseMission.title,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (baseMission.rewardPoints > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '+${baseMission.rewardPoints}P',
                              style: const TextStyle(
                                color: Color(0xFFF33D76),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      baseMission.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (completed) ...[
                      const SizedBox(height: 11),
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFF75283),
                            size: 17,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '오늘 완료',
                            style: TextStyle(
                              color: Color(0xFFF33D76),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ] else if (isHabitMission) ...[
                      const SizedBox(height: 11),
                      const Row(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            color: AppColors.mutedText,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '아직 실천 전',
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else if (target != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_formatNumber(mission.progressValue)}'
                              ' / ${_formatNumber(target)}'
                              '${_unitSuffix(baseMission.targetUnit)}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (progressValue != null)
                            Text(
                              '${progressValue.round()}%',
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: ((progressValue ?? 0) / 100).toDouble(),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEDF1F8),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.blue,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 11),
                      const Text(
                        '실천 후 완료할 수 있어요.',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _missionIcon(String missionType) {
  final normalized = missionType.toUpperCase();

  if (normalized.contains('WALK') ||
      normalized.contains('STEP') ||
      normalized.contains('ACTIVITY') ||
      normalized.contains('EXERCISE')) {
    return Icons.directions_walk_rounded;
  }

  if (normalized.contains('FOOD') ||
      normalized.contains('DIET') ||
      normalized.contains('NUTRITION')) {
    return Icons.restaurant_rounded;
  }

  if (normalized.contains('SLEEP')) {
    return Icons.bedtime_outlined;
  }

  if (normalized.contains('PRESSURE') ||
      normalized.contains('BP') ||
      normalized.contains('CHECK')) {
    return Icons.monitor_heart_outlined;
  }

  return Icons.favorite_outline_rounded;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}

String _unitSuffix(String? unit) {
  final normalized = unit?.trim();

  if (normalized == null || normalized.isEmpty) {
    return '';
  }

  return ' $normalized';
}

class _BomiEncouragementCard extends StatelessWidget {
  const _BomiEncouragementCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3F7), Color(0xFFF7FAFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0EA)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Image.asset(
              'assets/images/bomi/bomi_health_wave.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보미가 응원해요!',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '오늘도 작은 실천 하나면 충분해요.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0E9)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEEF3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFF75283),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '건강 미션을 불러오지 못했어요',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              side: const BorderSide(color: Color(0xFFD9E2EF)),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
