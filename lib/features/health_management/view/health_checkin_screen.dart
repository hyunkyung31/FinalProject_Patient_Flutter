import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/health_mission.dart';
import '../repository/health_mission_repository.dart';

class HealthCheckInResult {
  const HealthCheckInResult({
    required this.alreadyCompleted,
    this.awardedPoints,
  });

  final bool alreadyCompleted;
  final double? awardedPoints;
}

class HealthCheckInScreen extends StatefulWidget {
  const HealthCheckInScreen({
    super.key,
    required this.repository,
    required this.mission,
  });

  final HealthMissionRepository repository;
  final PatientHealthMission mission;

  @override
  State<HealthCheckInScreen> createState() => _HealthCheckInScreenState();
}

enum _BreathingPhase { ready, inhale, hold, exhale, complete }

class _HealthCheckInScreenState extends State<HealthCheckInScreen> {
  int _step = 0;
  String? _mood;

  Timer? _timer;
  int _secondsLeft = 60;
  int _phaseSecondsLeft = 4;
  bool _running = false;
  bool _breathingDone = false;
  bool _submitting = false;
  _BreathingPhase _phase = _BreathingPhase.ready;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectMood(String mood) {
    setState(() => _mood = mood);
  }

  void _goToBreathing() {
    if (_mood == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘의 상태를 먼저 선택해 주세요.')));
      return;
    }

    setState(() => _step = 1);
  }

  void _startBreathing() {
    if (_running || _breathingDone) return;

    setState(() {
      _secondsLeft = 60;
      _phaseSecondsLeft = 4;
      _phase = _BreathingPhase.inhale;
      _running = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsLeft <= 1) {
        timer.cancel();
        _timer = null;

        setState(() {
          _secondsLeft = 0;
          _phaseSecondsLeft = 0;
          _phase = _BreathingPhase.complete;
          _running = false;
          _breathingDone = true;
        });
        return;
      }

      setState(() {
        _secondsLeft -= 1;
        _phaseSecondsLeft -= 1;

        if (_phaseSecondsLeft == 0) {
          _phase = switch (_phase) {
            _BreathingPhase.inhale => _BreathingPhase.hold,
            _BreathingPhase.hold => _BreathingPhase.exhale,
            _BreathingPhase.exhale => _BreathingPhase.inhale,
            _ => _BreathingPhase.inhale,
          };

          _phaseSecondsLeft = 4;
        }
      });
    });
  }

  void _goToSummary() {
    if (!_breathingDone) return;

    setState(() => _step = 2);
  }

  Future<void> _completeCheckIn() async {
    if (_submitting) return;

    if (widget.mission.isCompleted) {
      if (mounted) {
        Navigator.of(context).pop<HealthCheckInResult>(
          const HealthCheckInResult(alreadyCompleted: true),
        );
      }
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.repository.saveMissionLog(
        missionId: widget.mission.id,
        activityDate: DateTime.now(),
        achievedValue: 1,
        note: '\uc624\ub298\uc758 \ub450\uadfc \uccb4\ud06c\uc778 \uc644\ub8cc',
      );

      final completion = await widget.repository.completeMission(
        widget.mission.id,
      );

      if (!mounted) return;

      Navigator.of(context).pop<HealthCheckInResult>(
        HealthCheckInResult(
          alreadyCompleted: completion.alreadyCompleted,
          awardedPoints: completion.awardedPoints,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _submitting = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(healthMissionErrorMessage(error))));
    }
  }

  String get _timerText {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _moodLabel {
    return switch (_mood) {
      'COMFORTABLE' => '편안해요',
      'NORMAL' => '평소와 같아요',
      'UNCOMFORTABLE' => '조금 불편해요',
      _ => '-',
    };
  }

  String get _phaseTitle {
    return switch (_phase) {
      _BreathingPhase.ready => '호흡할 준비를 해볼까요?',
      _BreathingPhase.inhale => '천천히 들이마셔요',
      _BreathingPhase.hold => '잠시 편안하게 멈춰요',
      _BreathingPhase.exhale => '천천히 길게 내쉬어요',
      _BreathingPhase.complete => '1분 호흡을 마쳤어요',
    };
  }

  String get _phaseMessage {
    return switch (_phase) {
      _BreathingPhase.ready => '편한 자세로 앉아 보미의 안내에 맞춰 천천히 호흡해요.',
      _BreathingPhase.inhale => '코로 천천히 숨을 들이마셔요.',
      _BreathingPhase.hold => '힘주지 말고 편안하게 잠시 머물러요.',
      _BreathingPhase.exhale => '입이나 코로 천천히 숨을 내쉬어요.',
      _BreathingPhase.complete => '잘했어요! 1분 동안 나에게 집중했어요.',
    };
  }

  String get _bomiAsset {
    return switch (_phase) {
      _BreathingPhase.ready => 'assets/images/bomi/bomi_breath_ready.png',
      _BreathingPhase.inhale => 'assets/images/bomi/bomi_breath_inhale.png',
      _BreathingPhase.hold => 'assets/images/bomi/bomi_breath_hold.png',
      _BreathingPhase.exhale => 'assets/images/bomi/bomi_breath_exhale.png',
      _BreathingPhase.complete => 'assets/images/bomi/bomi_breath_complete.png',
    };
  }

  // ??? ???? ?? ?? ?? ??? ?? ???????.
  double get _breathRingScale {
    return switch (_phase) {
      _BreathingPhase.ready => 0.86,
      _BreathingPhase.inhale => 1.16,
      _BreathingPhase.hold => 1.16,
      _BreathingPhase.exhale => 0.82,
      _BreathingPhase.complete => 1.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          '오늘의 두근 체크인',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          _CheckInProgress(step: _step),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (_step) {
                0 => _MoodStep(
                  key: const ValueKey('mood'),
                  selectedMood: _mood,
                  onSelect: _selectMood,
                  onNext: _goToBreathing,
                ),
                1 => _BreathingStep(
                  key: const ValueKey('breathing'),
                  timerText: _timerText,
                  phaseSecondsLeft: _phaseSecondsLeft,
                  phaseTitle: _phaseTitle,
                  phaseMessage: _phaseMessage,
                  assetPath: _bomiAsset,
                  ringScale: _breathRingScale,
                  running: _running,
                  completed: _breathingDone,
                  onStart: _startBreathing,
                  onNext: _goToSummary,
                ),
                _ => _SummaryStep(
                  key: const ValueKey('summary'),
                  moodLabel: _moodLabel,
                  onComplete: () {
                    _completeCheckIn();
                  },
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInProgress extends StatelessWidget {
  const _CheckInProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final current = step + 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: current / 3,
                minHeight: 7,
                backgroundColor: const Color(0xFFE8EDF5),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF4E7DE9)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$current / 3',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodStep extends StatelessWidget {
  const _MoodStep({
    super.key,
    required this.selectedMood,
    required this.onSelect,
    required this.onNext,
  });

  final String? selectedMood;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      children: [
        SizedBox(
          height: 150,
          child: Image.asset(
            'assets/images/bomi/bomi_health_checkin.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '오늘은 어떠세요?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '지금의 몸과 마음 상태를 가볍게 돌아봐요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _MoodCard(
                emoji: '🙂',
                label: '편안해요',
                selected: selectedMood == 'COMFORTABLE',
                onTap: () => onSelect('COMFORTABLE'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MoodCard(
                emoji: '😐',
                label: '평소와\n같아요',
                selected: selectedMood == 'NORMAL',
                onTap: () => onSelect('NORMAL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MoodCard(
                emoji: '😟',
                label: '조금\n불편해요',
                selected: selectedMood == 'UNCOMFORTABLE',
                onTap: () => onSelect('UNCOMFORTABLE'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SafetyNotice(),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF75283),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text(
            '다음',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _BreathingStep extends StatelessWidget {
  const _BreathingStep({
    super.key,
    required this.timerText,
    required this.phaseSecondsLeft,
    required this.phaseTitle,
    required this.phaseMessage,
    required this.assetPath,
    required this.ringScale,
    required this.running,
    required this.completed,
    required this.onStart,
    required this.onNext,
  });

  final String timerText;
  final int phaseSecondsLeft;
  final String phaseTitle;
  final String phaseMessage;
  final String assetPath;
  final double ringScale;
  final bool running;
  final bool completed;
  final VoidCallback onStart;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        const Text(
          '오늘의 1분 미션',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFF75283),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '보미와 1분 숨쉬기',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEFF4), Color(0xFFF4F8FF)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Text(
                timerText,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 224,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ???? ???? ???? ???? ?? ??? ?
                    AnimatedScale(
                      scale: ringScale,
                      duration: const Duration(seconds: 4),
                      curve: Curves.easeInOutCubic,
                      child: Container(
                        width: 178,
                        height: 178,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x337EA6FF),
                          border: Border.all(
                            color: const Color(0x667EA6FF),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x267EA6FF),
                              blurRadius: 28,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedScale(
                      scale: ringScale,
                      duration: const Duration(seconds: 4),
                      curve: Curves.easeInOutCubic,
                      child: Container(
                        width: 136,
                        height: 136,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x557EA6FF),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 176,
                      height: 176,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: Image.asset(
                          assetPath,
                          key: ValueKey(assetPath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phaseTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (running) ...[
                const SizedBox(height: 8),
                Text(
                  '$phaseSecondsLeft',
                  style: const TextStyle(
                    color: Color(0xFFF75283),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                phaseMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              if (!running && !completed)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('시작하기'),
                  ),
                ),
              if (completed)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onNext,
                    child: const Text('체크인 마무리하기'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    super.key,
    required this.moodLabel,
    required this.onComplete,
  });

  final String moodLabel;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      children: [
        SizedBox(
          height: 190,
          child: Image.asset(
            'assets/images/bomi/bomi_breath_complete.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '오늘의 체크인 완료!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          '오늘의 나를 잠시 돌아보는 작은 실천을 완료했어요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.mood_rounded,
                label: '오늘의 상태',
                value: moodLabel,
              ),
              const Divider(height: 28),
              const _SummaryRow(
                icon: Icons.air_rounded,
                label: '1분 미션',
                value: '숨쉬기 완료',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SafetyNotice(),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onComplete,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF75283),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text(
            '건강관리로 돌아가기',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF2FF) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4E7DE9)
                  : const Color(0xFFE3E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 29)),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF75283)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF4E7DE9)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '심한 불편감이 있거나 증상이 지속되면 의료진의 안내를 받아 주세요. '
              '두근 체크인은 진단을 대신하지 않아요.',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
