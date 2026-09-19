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
import 'health_walk_screen.dart';

class HealthManagementScreen extends StatefulWidget {
  const HealthManagementScreen({
    super.key,
    required this.repository,
    this.checkInScreenBuilder,
    this.conceptSection,
    this.rewardRepository,
    this.embedded = false,
  });

  final HealthMissionRepository repository;
  final WidgetBuilder? checkInScreenBuilder;
  final Widget? conceptSection;
  final RewardRepository? rewardRepository;
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

    for (final mission in _missions) {
      if (mission.healthMission.code.trim().toUpperCase() == 'DAILY_CHECKIN') {
        checkInMission = mission;
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

  // Health Connect 기반 걸음 수 화면으로 이동한다.
  void _openWalk() {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const HealthWalkScreen()));
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

      return code != 'DAILY_CHECKIN' && code != 'DAILY_QUIZ';
    }).toList();

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
            _TodayCheckInCard(onTap: _openCheckIn),
            const SizedBox(height: 16),
            if (widget.conceptSection != null) ...[
              widget.conceptSection!,
              const SizedBox(height: 24),
            ] else ...[
              HealthActivitySection(
                onWalk: _openWalk,
                onQuiz: _openQuiz,
                onBingo: () => _showActivityPreparing('두근빙고'),
                onStudio: () => _showActivityPreparing('보미 스튜디오'),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7EBF1)),
          ),
          child: Row(
            children: [
              _RewardEntryIcon(),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '두근 리워드',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      balance == null
                          ? '포인트와 리워드를 확인해요.'
                          : '보유 ${balance}P · 포인트와 리워드를 확인해요.',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardEntryIcon extends StatelessWidget {
  const _RewardEntryIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Color(0xFFF1F6FD),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Icon(Icons.card_giftcard_rounded, color: AppColors.navy),
    );
  }
}

class _TodayCheckInCard extends StatelessWidget {
  const _TodayCheckInCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEF4), Color(0xFFFFF8FB)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘의 두근 체크인',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '지금, 보미와 함께 나의 하루를 돌아봐요.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 98,
                height: 100,
                child: Transform.scale(
                  scale: 1.2,
                  child: Image.asset(
                    'assets/images/bomi/bomi_health_checkin.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF75283),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text(
                '체크인 시작',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.favorite_rounded, color: Color(0xFFF75283)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보미가 응원해요!',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '완벽함보다 꾸준함이 더 중요해요. 오늘도 작은 실천 하나부터 시작해 보세요.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    height: 1.45,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
