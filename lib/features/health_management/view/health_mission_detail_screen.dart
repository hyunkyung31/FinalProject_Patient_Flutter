import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/health_mission.dart';
import '../repository/health_mission_repository.dart';
import '../service/health_connect_service.dart';

class HealthMissionDetailScreen extends StatefulWidget {
  const HealthMissionDetailScreen({
    super.key,
    required this.repository,
    required this.mission,
  });

  final HealthMissionRepository repository;
  final PatientHealthMission mission;

  @override
  State<HealthMissionDetailScreen> createState() =>
      _HealthMissionDetailScreenState();
}

class _HealthMissionDetailScreenState extends State<HealthMissionDetailScreen> {
  late PatientHealthMission _mission;

  Timer? _activityTimer;
  late int _activitySecondsLeft;
  bool _activityTimerDone = false;

  bool _working = false;
  bool _changed = false;

  final HealthConnectService _healthConnectService = HealthConnectService();
  HealthConnectStepsResult? _healthConnectSteps;
  bool _healthConnectLoading = false;

  String get _missionType =>
      _mission.healthMission.missionType.trim().toUpperCase();

  bool get _isWalk =>
      _missionType.contains('WALK') ||
      _missionType.contains('STEP') ||
      _missionType.contains('ACTIVITY');

  bool get _isStretch => _missionType.contains('STRETCH');

  bool get _isBreathing => _missionType.contains('BREATH');

  bool get _isTimedMission => _isStretch || _isBreathing;

  bool get _isHabitCheck =>
      _missionType.contains('HABIT') || _missionType.contains('CHECK');

  @override
  void initState() {
    super.initState();
    _mission = widget.mission;
    _activitySecondsLeft = _initialTimerSeconds();
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    super.dispose();
  }

  int _initialTimerSeconds() {
    final target = widget.mission.healthMission.targetValue;

    if (_isBreathing) {
      return ((target ?? 1) * 60).round().clamp(1, 3600);
    }

    if (_isStretch) {
      return ((target ?? 5) * 60).round().clamp(1, 3600);
    }

    return 60;
  }

  Future<void> _refreshMission() async {
    final missions = await widget.repository.getMissions();

    for (final item in missions) {
      if (item.id == _mission.id) {
        if (!mounted) return;

        setState(() {
          _mission = item;
        });
        return;
      }
    }
  }

  void _startActivityTimer() {
    if (_activityTimer != null || _activityTimerDone || _mission.isCompleted) {
      return;
    }

    _activityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activitySecondsLeft <= 1) {
        timer.cancel();
        _activityTimer = null;

        if (!mounted) return;

        setState(() {
          _activitySecondsLeft = 0;
          _activityTimerDone = true;
        });

        return;
      }

      if (!mounted) return;

      setState(() {
        _activitySecondsLeft -= 1;
      });
    });

    setState(() {});
  }

  Future<void> _saveAndComplete({
    required double achievedValue,
    String? note,
  }) async {
    if (_working || _mission.isCompleted) return;

    setState(() {
      _working = true;
    });

    try {
      await widget.repository.saveMissionLog(
        missionId: _mission.id,
        activityDate: DateTime.now(),
        achievedValue: achievedValue,
        note: note,
      );

      await _refreshMission();

      if (!_mission.targetReached) {
        _changed = true;

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('오늘의 실천을 기록했어요.')));
        return;
      }

      final result = await widget.repository.completeMission(_mission.id);

      if (!mounted) return;

      setState(() {
        _mission = result.mission;
      });

      _changed = true;

      await _showCompletionDialog(result);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(healthMissionErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _recordTimedMission() async {
    if (!_activityTimerDone) return;

    final target = _mission.healthMission.targetValue;

    if (target == null) return;

    await _saveAndComplete(
      achievedValue: target,
      note: _isStretch ? '스트레칭 타이머 완료' : '호흡 타이머 완료',
    );
  }

  Future<void> _recordHabitCheck() async {
    await _saveAndComplete(achievedValue: 1, note: '오늘 실천 완료');
  }

  Future<void> _completeMission() async {
    if (_working || _mission.isCompleted) return;

    setState(() {
      _working = true;
    });

    try {
      final result = await widget.repository.completeMission(_mission.id);

      if (!mounted) return;

      setState(() {
        _mission = result.mission;
      });

      _changed = true;

      await _showCompletionDialog(result);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(healthMissionErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _showCompletionDialog(HealthMissionCompletion result) async {
    final points = result.awardedPoints;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.favorite_rounded,
          color: Color(0xFFF75283),
          size: 38,
        ),
        title: Text(result.alreadyCompleted ? '이미 완료한 미션이에요' : '오늘의 미션 완료!'),
        content: Text(
          result.alreadyCompleted
              ? '완료 기록이 안전하게 유지되고 있어요.'
              : points != null && points > 0
              ? '${_formatNumber(points)}P가 적립됐어요.\n'
                    '오늘의 건강한 실천이 하나 더 쌓였어요.'
              : '오늘의 건강한 실천이 하나 더 쌓였어요.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectHealthSteps() async {
    if (_healthConnectLoading) {
      return;
    }

    setState(() {
      _healthConnectLoading = true;
    });

    final result = await _healthConnectService.readTodaySteps();

    if (!mounted) {
      return;
    }

    setState(() {
      _healthConnectSteps = result;
      _healthConnectLoading = false;
    });
  }

  Future<void> _recordGenericProgress() async {
    final target = _mission.healthMission.targetValue;

    if (target == null) {
      await _completeMission();
      return;
    }

    final result = await showModalBottomSheet<_MissionRecordInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MissionRecordSheet(mission: _mission),
    );

    if (result == null || !mounted) return;

    setState(() {
      _working = true;
    });

    try {
      await widget.repository.saveMissionLog(
        missionId: _mission.id,
        activityDate: DateTime.now(),
        achievedValue: result.value,
        note: result.note,
      );

      await _refreshMission();

      _changed = true;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mission.targetReached ? '기록했어요. 목표에 도달했어요!' : '오늘의 실천을 기록했어요.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(healthMissionErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Widget _buildActionArea() {
    if (_mission.isCompleted) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('완료한 미션'),
      );
    }

    if (_isWalk) {
      if (_mission.targetReached) {
        return FilledButton.icon(
          onPressed: _working ? null : _completeMission,
          icon: const Icon(Icons.favorite_rounded),
          label: const Text('미션 완료하기'),
        );
      }

      return FilledButton.icon(
        onPressed: _healthConnectLoading ? null : _connectHealthSteps,
        icon: const Icon(Icons.sync_rounded),
        label: Text(
          _healthConnectLoading
              ? '연동 중...'
              : _healthConnectSteps?.isReady == true
              ? '걸음 수 새로고침'
              : 'Health Connect 연결하기',
        ),
      );
    }

    if (_isTimedMission) {
      if (_mission.targetReached) {
        return FilledButton.icon(
          onPressed: _working ? null : _completeMission,
          icon: const Icon(Icons.favorite_rounded),
          label: const Text('미션 완료하기'),
        );
      }

      if (_activityTimerDone) {
        return FilledButton.icon(
          onPressed: _working ? null : _recordTimedMission,
          icon: const Icon(Icons.check_rounded),
          label: Text(_working ? '기록 중...' : '${_timedMissionName()} 완료 기록하기'),
        );
      }

      return FilledButton.icon(
        onPressed: _activityTimer != null ? null : _startActivityTimer,
        icon: Icon(
          _activityTimer != null
              ? Icons.hourglass_top_rounded
              : Icons.play_arrow_rounded,
        ),
        label: Text(
          _activityTimer != null
              ? '${_timerText()} 진행 중'
              : '${_timedMissionName()} 시작',
        ),
      );
    }

    if (_isHabitCheck) {
      return FilledButton.icon(
        onPressed: _working ? null : _recordHabitCheck,
        icon: const Icon(Icons.favorite_rounded),
        label: Text(_working ? '기록 중...' : '오늘 실천했어요'),
      );
    }

    if (_mission.targetReached) {
      return FilledButton.icon(
        onPressed: _working ? null : _completeMission,
        icon: const Icon(Icons.favorite_rounded),
        label: const Text('미션 완료하기'),
      );
    }

    return FilledButton.icon(
      onPressed: _working ? null : _recordGenericProgress,
      icon: const Icon(Icons.edit_rounded),
      label: Text(_working ? '저장 중...' : '오늘 실천 기록하기'),
    );
  }

  String _timerText() {
    final minutes = _activitySecondsLeft ~/ 60;
    final seconds = _activitySecondsLeft % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _timedMissionName() {
    if (_isStretch) return '스트레칭';
    if (_isBreathing) return '호흡';
    return '활동';
  }

  @override
  Widget build(BuildContext context) {
    final baseMission = _mission.healthMission;
    final target = baseMission.targetValue;

    final percent =
        _mission.progressPercent ??
        (target != null && target > 0
            ? ((_mission.progressValue / target) * 100).clamp(0, 100).toDouble()
            : null);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          title: const Text(
            '미션 상세',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_changed),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            _MissionHeaderCard(mission: _mission),
            const SizedBox(height: 16),

            if (_isHabitCheck)
              _HabitStatusCard(completed: _mission.isCompleted)
            else if (target != null)
              _ProgressCard(mission: _mission, percent: percent ?? 0)
            else
              _SimpleMissionCard(completed: _mission.isCompleted),

            if (_isWalk) ...[
              const SizedBox(height: 16),
              _HealthConnectCard(
                completed: _mission.isCompleted,
                loading: _healthConnectLoading,
                result: _healthConnectSteps,
                onConnect: _connectHealthSteps,
              ),
            ],

            if (_isTimedMission) ...[
              const SizedBox(height: 16),
              _TimedMissionCard(
                title: _timedMissionName(),
                timerText: _timerText(),
                running: _activityTimer != null,
                timerDone: _activityTimerDone,
                completed: _mission.isCompleted,
              ),
            ],

            if (_isHabitCheck && !_mission.isCompleted) ...[
              const SizedBox(height: 16),
              const _HabitGuideCard(),
            ],

            const SizedBox(height: 16),
            _MissionInfoCard(mission: _mission),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: _buildActionArea(),
        ),
      ),
    );
  }
}

class _MissionHeaderCard extends StatelessWidget {
  const _MissionHeaderCard({required this.mission});

  final PatientHealthMission mission;

  @override
  Widget build(BuildContext context) {
    final baseMission = mission.healthMission;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDF3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _missionIcon(baseMission.missionType),
              color: const Color(0xFFF75283),
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            baseMission.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            baseMission.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _HealthConnectCard extends StatelessWidget {
  const _HealthConnectCard({
    required this.completed,
    required this.loading,
    required this.result,
    required this.onConnect,
  });

  final bool completed;
  final bool loading;
  final HealthConnectStepsResult? result;
  final VoidCallback onConnect;

  bool get _hasAccess =>
      result?.state == HealthConnectStepsState.ready ||
      result?.state == HealthConnectStepsState.noData;

  String get _statusText {
    if (loading) {
      return 'Health Connect에서 오늘의 걸음 기록을 확인하고 있어요.';
    }

    if (result?.state == HealthConnectStepsState.ready) {
      return '연동됨 · 오늘 ${result?.steps ?? 0}걸음';
    }

    if (result?.state == HealthConnectStepsState.noData) {
      return '연동됨 · 오늘 확인된 걸음 기록이 없어요.';
    }

    if (result != null) {
      return result!.message ?? 'Health Connect 연결을 확인해 주세요.';
    }

    return 'Health Connect와 연결하면 오늘의 걸음 수를 확인할 수 있어요.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                color: Color(0xFF4E7DE9),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Android Health Connect',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_hasAccess)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF39A96B),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            completed ? '오늘의 걷기 미션을 완료했어요.' : _statusText,
            style: TextStyle(
              color: _hasAccess ? AppColors.navy : AppColors.mutedText,
              fontSize: 12,
              fontWeight: _hasAccess ? FontWeight.w700 : FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (_hasAccess && !completed) ...[
            const SizedBox(height: 8),
            const Text(
              '걸음 수는 현재 확인용이며, 20분 걷기 시간으로 '
              '임의 환산하지 않아요.',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
          if (!completed) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: loading ? null : onConnect,
              icon: Icon(
                _hasAccess ? Icons.refresh_rounded : Icons.link_rounded,
              ),
              label: Text(
                loading
                    ? '확인 중...'
                    : _hasAccess
                    ? '걸음 수 새로고침'
                    : 'Health Connect 연결하기',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimedMissionCard extends StatelessWidget {
  const _TimedMissionCard({
    required this.title,
    required this.timerText,
    required this.running,
    required this.timerDone,
    required this.completed,
  });

  final String title;
  final String timerText;
  final bool running;
  final bool timerDone;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final finished = completed || timerDone;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F5), Color(0xFFF4F8FF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            '$title 타이머',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 108,
            height: 108,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD6E3), width: 5),
            ),
            child: finished
                ? const Icon(
                    Icons.check_rounded,
                    color: Color(0xFFF75283),
                    size: 52,
                  )
                : Text(
                    timerText,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            completed
                ? '오늘의 $title을 완료했어요.'
                : timerDone
                ? '$title 시간이 끝났어요.'
                : running
                ? '천천히 진행하고 있어요.'
                : '준비되면 아래 버튼을 눌러 시작해 보세요.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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

class _HabitStatusCard extends StatelessWidget {
  const _HabitStatusCard({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFFFF0F5) : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFFFFE3EC)
                  : const Color(0xFFF1F6FF),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.restaurant_rounded,
              color: completed
                  ? const Color(0xFFF75283)
                  : const Color(0xFF4E7DE9),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              completed ? '오늘의 건강한 선택을 실천했어요.' : '실천했다면 아래 버튼을 한 번 눌러주세요.',
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitGuideCard extends StatelessWidget {
  const _HabitGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE59A24)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '국물은 조금 남기고, 소스나 양념은 필요한 만큼만 '
              '사용하는 작은 선택부터 시작해 보세요.',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.mission, required this.percent});

  final PatientHealthMission mission;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final target = mission.healthMission.targetValue ?? 0;
    final unit = mission.healthMission.targetUnit?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text(
            '현재 진행',
            style: TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_formatNumber(mission.progressValue)}'
            ' / ${_formatNumber(target)}'
            '${unit.isEmpty ? '' : ' $unit'}',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1).toDouble(),
              minHeight: 12,
              backgroundColor: const Color(0xFFEDF1F8),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF75283)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percent.round()}%',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleMissionCard extends StatelessWidget {
  const _SimpleMissionCard({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFFFF0F5) : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.favorite_border_rounded,
            color: completed ? const Color(0xFFF75283) : AppColors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              completed ? '오늘 실천을 완료했어요.' : '오늘의 실천을 시작해 보세요.',
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionInfoCard extends StatelessWidget {
  const _MissionInfoCard({required this.mission});

  final PatientHealthMission mission;

  @override
  Widget build(BuildContext context) {
    final baseMission = mission.healthMission;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '미션 정보',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: '주기',
            value: _frequencyLabel(baseMission.frequencyType),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: '완료 보상',
            value: baseMission.rewardPoints > 0
                ? '${baseMission.rewardPoints}P'
                : '별도 포인트 없음',
          ),
          if (mission.endsOn != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              label: '미션 기간',
              value:
                  '${_dateText(mission.startsOn)} ~ '
                  '${_dateText(mission.endsOn!)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionRecordInput {
  const _MissionRecordInput({required this.value, this.note});

  final double value;
  final String? note;
}

class _MissionRecordSheet extends StatefulWidget {
  const _MissionRecordSheet({required this.mission});

  final PatientHealthMission mission;

  @override
  State<_MissionRecordSheet> createState() => _MissionRecordSheetState();
}

class _MissionRecordSheetState extends State<_MissionRecordSheet> {
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(
      _valueController.text.trim().replaceAll(',', ''),
    );

    if (value == null) {
      setState(() {
        _error = '오늘 수행한 값을 숫자로 입력해 주세요.';
      });
      return;
    }

    Navigator.of(context).pop(
      _MissionRecordInput(
        value: value,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.mission.healthMission.targetUnit?.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '오늘 실천 기록하기',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unit == null || unit.isEmpty
                ? '오늘 수행한 값을 입력해 주세요.'
                : '오늘 수행한 양을 $unit 단위로 입력해 주세요.',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '오늘 수행량',
              suffixText: unit,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: '한마디 메모 (선택)',
              hintText: '오늘의 실천을 짧게 남겨보세요.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _submit, child: const Text('기록 저장')),
        ],
      ),
    );
  }
}

IconData _missionIcon(String missionType) {
  final normalized = missionType.toUpperCase();

  if (normalized.contains('WALK') ||
      normalized.contains('STEP') ||
      normalized.contains('ACTIVITY')) {
    return Icons.directions_walk_rounded;
  }

  if (normalized.contains('STRETCH')) {
    return Icons.self_improvement_rounded;
  }

  if (normalized.contains('BREATH')) {
    return Icons.air_rounded;
  }

  if (normalized.contains('HABIT') ||
      normalized.contains('FOOD') ||
      normalized.contains('DIET') ||
      normalized.contains('NUTRITION')) {
    return Icons.restaurant_rounded;
  }

  return Icons.favorite_outline_rounded;
}

String _frequencyLabel(String value) {
  return switch (value.toUpperCase()) {
    'DAILY' => '매일',
    'WEEKLY' => '매주',
    'ONE_TIME' => '한 번',
    _ => value,
  };
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}

String _dateText(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}.$month.$day';
}
