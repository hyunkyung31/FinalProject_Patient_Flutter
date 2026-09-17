import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/health_mission.dart';
import '../repository/health_mission_repository.dart';
import 'health_mission_detail_screen.dart';

class HealthManagementScreen extends StatefulWidget {
  const HealthManagementScreen({
    super.key,
    required this.repository,
    this.checkInScreenBuilder,
    this.conceptSection,
  });

  final HealthMissionRepository repository;
  final WidgetBuilder? checkInScreenBuilder;
  final Widget? conceptSection;

  @override
  State<HealthManagementScreen> createState() => _HealthManagementScreenState();
}

class _HealthManagementScreenState extends State<HealthManagementScreen> {
  List<PatientHealthMission> _missions = const [];
  bool _loading = true;
  String? _error;

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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = healthMissionErrorMessage(error);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final completedCount = _missions.where((item) => item.isCompleted).length;
    final totalCount = _missions.length;
    final completionRate = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          '건강관리',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
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
            if (widget.checkInScreenBuilder != null) ...[
              _TodayCheckInCard(
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: widget.checkInScreenBuilder!),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            if (widget.conceptSection != null) ...[
              widget.conceptSection!,
              const SizedBox(height: 24),
            ] else ...[
              _TodayMissionHero(
                completedCount: completedCount,
                totalCount: totalCount,
                completionRate: completionRate,
              ),
              const SizedBox(height: 24),
            ],
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
            if (_loading)
              const _LoadingState()
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else if (_missions.isEmpty)
              const _EmptyState()
            else
              ..._missions.map(
                (mission) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MissionCard(
                    mission: mission,
                    onTap: () => _openMission(mission),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            const _BomiEncouragementCard(),
          ],
        ),
      ),
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

class _TodayMissionHero extends StatelessWidget {
  const _TodayMissionHero({
    required this.completedCount,
    required this.totalCount,
    required this.completionRate,
  });

  final int completedCount;
  final int totalCount;
  final double completionRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFFFF8FB)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD9E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘의 두근',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (totalCount == 0) ...[
                      const Text(
                        '오늘의 미션을 준비하고 있어요',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '새로운 건강 미션이 생기면 이곳에서 바로 알려드릴게요.',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ] else ...[
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: '오늘 ',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '$completedCount',
                              style: const TextStyle(
                                color: Color(0xFFF33D76),
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: ' / $totalCount 완료',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '오늘 할 수 있는 만큼 천천히 이어가도 괜찮아요.',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 40,
                  color: Color(0xFFF75283),
                ),
              ),
            ],
          ),
          if (totalCount > 0) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completionRate,
                minHeight: 10,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF75283)),
              ),
            ),
          ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 42,
            color: Color(0xFFF2A1B9),
          ),
          SizedBox(height: 14),
          Text(
            '아직 오늘의 미션이 없어요',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            '미션이 준비되면 오늘의 건강 실천을\n이곳에서 확인할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
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
