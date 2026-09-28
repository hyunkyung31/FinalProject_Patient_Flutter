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
    required this.breathMission,
  });

  final HealthMissionRepository repository;
  final PatientHealthMission mission;

  // 체크인 안의 1분 호흡 수행을 별도 DAILY_BREATH 미션으로 기록한다.
  final PatientHealthMission breathMission;

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
  bool _breathingSynced = false;
  bool _submitting = false;
  Future<bool>? _breathingSyncFuture;
  _BreathingPhase _phase = _BreathingPhase.ready;

  @override
  void initState() {
    super.initState();

    _breathingSynced = widget.breathMission.isCompleted;
  }

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

  Future<bool> _syncBreathingMission({bool showError = true}) async {
    if (_breathingSynced || widget.breathMission.isCompleted) {
      _breathingSynced = true;
      return true;
    }

    try {
      await widget.repository.saveMissionLog(
        missionId: widget.breathMission.id,
        activityDate: DateTime.now(),
        achievedValue: 1,
        note: '보미와 1분 호흡 완료',
      );

      await widget.repository.completeMission(widget.breathMission.id);

      _breathingSynced = true;
      return true;
    } catch (error) {
      if (mounted && showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '1분 호흡은 완료했지만 기록 동기화에 실패했어요. '
              '${healthMissionErrorMessage(error)}',
            ),
          ),
        );
      }

      return false;
    }
  }

  Future<bool> _ensureBreathingMissionSynced({bool showError = true}) {
    if (_breathingSynced || widget.breathMission.isCompleted) {
      return Future<bool>.value(true);
    }

    final existing = _breathingSyncFuture;

    if (existing != null) {
      return existing;
    }

    final future = _syncBreathingMission(showError: showError);

    _breathingSyncFuture = future;

    future.whenComplete(() {
      if (identical(_breathingSyncFuture, future)) {
        _breathingSyncFuture = null;
      }
    });

    return future;
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

        // 60초를 실제로 마친 순간 호흡 미션을 즉시 서버에 반영한다.
        unawaited(_ensureBreathingMissionSynced());

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
      // 60초 완료 직후 동기화가 실패했거나 아직 진행 중이라면
      // 체크인 완료 전에 DAILY_BREATH 기록을 한 번 더 보장한다.
      if (_breathingDone) {
        final breathSynced = await _ensureBreathingMissionSynced(
          showError: false,
        );

        if (!breathSynced) {
          if (!mounted) return;

          setState(() => _submitting = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('1분 호흡 기록을 저장하지 못했어요. 잠시 후 다시 시도해 주세요.'),
            ),
          );
          return;
        }
      }

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

      await _showCompletionCelebration(completion.awardedPoints);

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

  Future<void> _showCompletionCelebration(double? awardedPoints) async {
    final dialogFuture = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '체크인 완료',
      barrierColor: const Color(0x330D1B33),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) {
        return _CheckInCelebrationOverlay(awardedPoints: awardedPoints);
      },
      transitionBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );

    // 컨페티와 보상 안내를 짧게 보여준 뒤 건강관리 홈으로 돌아간다.
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
    await dialogFuture;
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
    final timerParts = timerText.split(':');
    final minutes = timerParts.length == 2
        ? int.tryParse(timerParts[0]) ?? 1
        : 1;
    final seconds = timerParts.length == 2
        ? int.tryParse(timerParts[1]) ?? 0
        : 0;

    final remainingSeconds = (minutes * 60 + seconds).clamp(0, 60).toInt();
    final elapsedSeconds = 60 - remainingSeconds;
    final overallProgress = (elapsedSeconds / 60).clamp(0.0, 1.0);

    String? endingCue;

    if (running && remainingSeconds > 0) {
      if (remainingSeconds <= 4) {
        endingCue = '마지막 호흡이에요';
      } else if (remainingSeconds <= 10) {
        endingCue = '거의 다 왔어요';
      } else if (remainingSeconds <= 15) {
        endingCue = '조금만 더 함께해요';
      }
    }

    final displayMessage =
        running && remainingSeconds > 0 && remainingSeconds <= 4
        ? '마지막 숨을 천천히 이어가며 마무리해요.'
        : phaseMessage;

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
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEFF4), Color(0xFFF4F8FF)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              // 전체 1분 흐름은 현재 4초 호흡 단계와 분리해서 보여준다.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 94,
                      height: 94,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(
                              value: overallProgress,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0xFFE3E9F5),
                              color: const Color(0xFF4E7DE9),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: Color(0xFF6E7F9E),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timerText,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completed ? '1분 호흡 완료' : '1분 호흡 진행',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            completed
                                ? '1분 호흡을 모두 마쳤어요'
                                : running
                                ? '$remainingSeconds초 남았어요'
                                : '천천히 1분 동안 함께해요',
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: overallProgress,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE7ECF5),
                              color: const Color(0xFF7EA6FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 기존 외곽 동심원 대신 보미 자체가 호흡 리듬에 맞춰 움직인다.
              SizedBox(
                height: 205,
                child: Center(
                  child: AnimatedScale(
                    scale: running ? ringScale : 1,
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeInOutCubic,
                    child: Transform.scale(
                      scale: 1.30,
                      child: SizedBox(
                        width: 190,
                        height: 190,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          child: Image.asset(
                            assetPath,
                            key: ValueKey(assetPath),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: endingCue == null
                    ? const SizedBox(key: ValueKey('no-ending-cue'), height: 0)
                    : Container(
                        key: ValueKey(endingCue),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5ED),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          endingCue,
                          style: const TextStyle(
                            color: Color(0xFFF75283),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
              ),

              Text(
                phaseTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),

              if (running) ...[
                const SizedBox(height: 6),
                Text(
                  '$phaseSecondsLeft',
                  style: const TextStyle(
                    color: Color(0xFFF75283),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  displayMessage,
                  key: ValueKey(displayMessage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (!running && !completed)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('1분 시작하기'),
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

class _CheckInCelebrationOverlay extends StatelessWidget {
  const _CheckInCelebrationOverlay({required this.awardedPoints});

  final double? awardedPoints;

  String? get _rewardText {
    final points = awardedPoints;

    if (points == null || points <= 0) return null;

    final value = points == points.roundToDouble()
        ? points.toInt().toString()
        : points.toStringAsFixed(1);

    return '+${value}P 적립';
  }

  Widget _piece({
    required double width,
    required double height,
    required double progress,
    required double x,
    required double fall,
    required double sway,
    required double rotation,
    required Color color,
  }) {
    final fadeStart = ((progress - 0.76) / 0.24).clamp(0.0, 1.0).toDouble();

    return Positioned(
      left: width * x + progress * sway,
      top: -20 + height * fall * progress,
      child: Opacity(
        opacity: 1 - fadeStart,
        child: Transform.rotate(
          angle: progress * rotation,
          child: Container(
            width: 8,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewardText = _rewardText;

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1300),
          curve: Curves.easeOut,
          builder: (context, progress, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                // 처음에는 살짝 크게 튀고 부드럽게 원래 크기로 돌아온다.
                final cardScale = progress < 0.5
                    ? 0.80 + (progress / 0.5) * 0.32
                    : 1.12 - ((progress - 0.5) / 0.5) * 0.12;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Transform.scale(
                        scale: cardScale,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x220D1B33),
                                  blurRadius: 28,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SizedBox(
                                      height: 116,
                                      child: Image.asset(
                                        'assets/images/bomi/bomi_breath_complete.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const Positioned(
                                      top: 0,
                                      right: -6,
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 21,
                                        color: Color(0xFFFFC84A),
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: 12,
                                      left: -4,
                                      child: Icon(
                                        Icons.favorite_rounded,
                                        size: 16,
                                        color: Color(0xFFFFA6BE),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  '오늘의 체크인 완료!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  '오늘도 잘했어요 💗',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (rewardText != null) ...[
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEAF1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.card_giftcard_rounded,
                                          size: 17,
                                          color: Color(0xFFF75283),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          rewardText,
                                          style: const TextStyle(
                                            color: Color(0xFFF75283),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.07,
                      fall: 0.34,
                      sway: 22,
                      rotation: 5.2,
                      color: const Color(0xFFF75283),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.16,
                      fall: 0.53,
                      sway: -17,
                      rotation: -5.0,
                      color: const Color(0xFFFFC84A),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.27,
                      fall: 0.42,
                      sway: 21,
                      rotation: 6.0,
                      color: const Color(0xFF82BFFF),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.38,
                      fall: 0.59,
                      sway: -19,
                      rotation: -5.7,
                      color: const Color(0xFFF6A4BD),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.49,
                      fall: 0.37,
                      sway: 15,
                      rotation: 4.8,
                      color: const Color(0xFFFFD76A),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.60,
                      fall: 0.55,
                      sway: -22,
                      rotation: -6.2,
                      color: const Color(0xFF9BDCC9),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.71,
                      fall: 0.40,
                      sway: 19,
                      rotation: 5.5,
                      color: const Color(0xFFF75283),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.82,
                      fall: 0.56,
                      sway: -16,
                      rotation: -5.4,
                      color: const Color(0xFFFFC84A),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.91,
                      fall: 0.35,
                      sway: -20,
                      rotation: 6.1,
                      color: const Color(0xFF8FC5FF),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.12,
                      fall: 0.68,
                      sway: 24,
                      rotation: -5.9,
                      color: const Color(0xFFF0A5D0),
                    ),
                    _piece(
                      width: width,
                      height: height,
                      progress: progress,
                      x: 0.86,
                      fall: 0.69,
                      sway: -24,
                      rotation: 6.0,
                      color: const Color(0xFF91D5C1),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
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
          height: 220,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.72, end: 1.16),
            duration: const Duration(milliseconds: 430),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/bomi/bomi_breath_complete.png',
                  fit: BoxFit.contain,
                ),
                const Positioned(
                  top: 7,
                  right: 46,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFFC84A),
                    size: 23,
                  ),
                ),
                const Positioned(
                  top: 43,
                  left: 43,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFF58AA8),
                    size: 15,
                  ),
                ),
                const Positioned(
                  bottom: 24,
                  right: 35,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFFA6BE),
                    size: 15,
                  ),
                ),
              ],
            ),
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
