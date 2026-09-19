import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/health_mission.dart';
import '../repository/health_mission_repository.dart';
import '../service/health_connect_service.dart';

class HealthWalkScreen extends StatefulWidget {
  const HealthWalkScreen({
    super.key,
    required this.repository,
    required this.mission,
  });

  final HealthMissionRepository repository;
  final PatientHealthMission mission;

  @override
  State<HealthWalkScreen> createState() => _HealthWalkScreenState();
}

class _HealthWalkScreenState extends State<HealthWalkScreen>
    with SingleTickerProviderStateMixin {
  static const int _goalSteps = 5000;
  static const Color _pink = Color(0xFFF75283);
  static const Color _softPink = Color(0xFFFFEEF4);
  static const Color _softBlue = Color(0xFFF0F6FF);

  final HealthConnectService _healthConnectService = HealthConnectService();

  HealthConnectStepsResult? _result;
  DateTime? _lastUpdatedAt;
  bool _loading = false;
  bool _isPreviewMode = false;

  // ?? ?? ???? ?? ??? ???? ?? ????.
  late final AnimationController _pathController;
  double _displayProgress = 0;
  double _animationStart = 0;
  double _animationTarget = 0;
  int _displaySteps = 0;
  int _animationStartSteps = 0;
  int _animationTargetSteps = 0;

  @override
  void initState() {
    super.initState();

    _pathController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..addListener(() {
          if (!mounted) return;

          final curved = Curves.easeOutCubic.transform(_pathController.value);

          setState(() {
            _displayProgress =
                _animationStart +
                ((_animationTarget - _animationStart) * curved);

            _displaySteps =
                (_animationStartSteps +
                        ((_animationTargetSteps - _animationStartSteps) *
                            curved))
                    .round();
          });
        });

    // ??? ??? ?? ?? ?? ?? ???? ????.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSteps();
      }
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _animatePathTo(double target, {required int targetSteps}) {
    _animationStart = _displayProgress;
    _animationTarget = target.clamp(0.0, 1.0).toDouble();

    _animationStartSteps = _displaySteps;
    _animationTargetSteps = targetSteps < 0 ? 0 : targetSteps;

    final progressUnchanged =
        (_animationTarget - _animationStart).abs() < 0.001;
    final stepsUnchanged = _animationTargetSteps == _animationStartSteps;

    if (progressUnchanged && stepsUnchanged) {
      setState(() {
        _displayProgress = _animationTarget;
        _displaySteps = _animationTargetSteps;
      });
      return;
    }

    _pathController.forward(from: 0);
  }

  // ?? Health Connect ???? ???? ?? ??? ????.
  // ?? Health Connect ?? ???? ?? ?? ??? ????.
  void _previewWalkAnimation() {
    if (!kDebugMode) return;

    const previewSteps = 3284;

    setState(() {
      _isPreviewMode = true;
      _result = const HealthConnectStepsResult(
        state: HealthConnectStepsState.ready,
        steps: previewSteps,
      );
      _lastUpdatedAt = DateTime.now();
    });

    _animatePathTo(previewSteps / _goalSteps, targetSteps: previewSteps);
  }

  Future<void> _syncRealStepsToMission(int steps) async {
    try {
      // Health Connect에서 실제로 읽은 오늘 걸음 수만 서버에 저장한다.
      // Debug 미리보기용 걸음 수는 이 메서드를 호출하지 않는다.
      await widget.repository.saveMissionLog(
        missionId: widget.mission.id,
        activityDate: DateTime.now(),
        achievedValue: steps.toDouble(),
        note: 'Health Connect 오늘 걸음 수 자동 동기화',
      );

      final target = widget.mission.healthMission.targetValue;

      if (target != null && steps >= target) {
        // 5,000걸음 목표 달성 시 DAILY_WALK 미션 자체도 완료 처리한다.
        // DAILY_WALK 보상은 현재 0P이며 빙고 보상과는 별도다.
        await widget.repository.completeMission(widget.mission.id);
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('걸음 수는 확인했지만 건강관리 기록 동기화에 실패했어요.')),
      );
    }
  }

  Future<void> _loadSteps() async {
    if (_loading) return;

    setState(() => _loading = true);

    final result = await _healthConnectService.readTodaySteps();

    if (!mounted) return;

    setState(() {
      _isPreviewMode = false;
      _result = result;
      _lastUpdatedAt = result.isReady ? DateTime.now() : _lastUpdatedAt;
    });

    if (result.isReady) {
      await _syncRealStepsToMission(result.steps ?? 0);

      if (!mounted) return;
    }

    setState(() {
      _loading = false;
    });

    // Debug ???? ?? ?? ?? 0?? ???? ?? ??? ????.
    if (kDebugMode && result.isReady && (result.steps ?? 0) == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;

      _previewWalkAnimation();
      return;
    }

    // ?? ?? ???? ??? ?? ??? ???? ????.
    _animatePathTo(
      result.isReady ? _progress : 0,
      targetSteps: result.isReady ? (result.steps ?? 0) : 0,
    );
  }

  int? get _steps => _result?.steps;

  double get _progress {
    final steps = _steps ?? 0;
    return (steps / _goalSteps).clamp(0.0, 1.0).toDouble();
  }

  int? get _remainingSteps {
    final steps = _result?.isReady == true ? _displaySteps : null;
    if (steps == null) return null;
    return math.max(0, _goalSteps - steps);
  }

  String get _statusTitle {
    if (_loading) {
      return '걸음 기록을 불러오고 있어요';
    }

    return switch (_result?.state) {
      HealthConnectStepsState.ready => 'Health Connect 연결됨',
      HealthConnectStepsState.noData => '오늘 기록이 아직 없어요',
      HealthConnectStepsState.permissionDenied => '걸음 수 권한이 필요해요',
      HealthConnectStepsState.unavailable => 'Health Connect를 사용할 수 없어요',
      HealthConnectStepsState.unsupportedPlatform => 'Android에서 확인할 수 있어요',
      HealthConnectStepsState.error => '걸음 기록을 불러오지 못했어요',
      null => '오늘 걸음 수를 확인해볼까요?',
    };
  }

  String get _statusMessage {
    if (_loading) {
      return 'Health Connect\uc5d0\uc11c \uc624\ub298 \uae30\ub85d\uc744 \ud655\uc778\ud558\uace0 \uc788\uc5b4\uc694.';
    }

    if (_isPreviewMode) {
      return '\uac1c\ubc1c \ubbf8\ub9ac\ubcf4\uae30 \u00b7 3,284\uac78\uc74c \uc774\ub3d9 \uc560\ub2c8\uba54\uc774\uc158\uc744 \ud45c\uc2dc\ud558\uace0 \uc788\uc5b4\uc694.';
    }

    return switch (_result?.state) {
      HealthConnectStepsState.ready =>
        'Health Connect\uc5d0\uc11c \uc624\ub298\uc758 \uac78\uc74c \uc218\ub97c \ubd88\ub7ec\uc654\uc5b4\uc694.',
      HealthConnectStepsState.noData =>
        'Health Connect\uc5d0\uc11c \ud655\uc778\ud560 \uc218 \uc788\ub294 \uc624\ub298 \uac78\uc74c \uae30\ub85d\uc774 \uc5c6\uc5b4\uc694.',
      HealthConnectStepsState.permissionDenied =>
        '\uc2e0\uccb4 \ud65c\ub3d9 \ubc0f Health Connect \uc77d\uae30 \uad8c\ud55c\uc744 \ud5c8\uc6a9\ud574\uc8fc\uc138\uc694.',
      HealthConnectStepsState.unavailable =>
        'Health Connect \uc124\uce58 \ub610\ub294 \uc5c5\ub370\uc774\ud2b8 \uc0c1\ud0dc\ub97c \ud655\uc778\ud574\uc8fc\uc138\uc694.',
      HealthConnectStepsState.unsupportedPlatform =>
        '\ub9ac\ub4ec\uc0b0\ucc45\uc758 \uac78\uc74c \uc218 \uc5f0\ub3d9\uc740 Android Health Connect\ub97c \uc0ac\uc6a9\ud574\uc694.',
      HealthConnectStepsState.error =>
        '\uc7a0\uc2dc \ud6c4 \ub2e4\uc2dc \uac78\uc74c \uae30\ub85d\uc744 \ud655\uc778\ud574\uc8fc\uc138\uc694.',
      null =>
        'Health Connect\uc640 \uc5f0\uacb0\ud558\uba74 \uc624\ub298\uc758 \uac78\uc74c \uae30\ub85d\uc744 \ud655\uc778\ud560 \uc218 \uc788\uc5b4\uc694.',
    };
  }

  String get _buttonText {
    if (_loading) return '불러오는 중...';

    return switch (_result?.state) {
      HealthConnectStepsState.ready => '걸음 수 새로고침',
      HealthConnectStepsState.permissionDenied => '권한 다시 요청',
      HealthConnectStepsState.noData => '다시 확인',
      _ => 'Health Connect와 연결하기',
    };
  }

  IconData get _statusIcon {
    if (_loading) return Icons.sync_rounded;

    return switch (_result?.state) {
      HealthConnectStepsState.ready => Icons.check_circle_rounded,
      HealthConnectStepsState.permissionDenied => Icons.lock_outline_rounded,
      HealthConnectStepsState.noData => Icons.directions_walk_rounded,
      HealthConnectStepsState.unavailable => Icons.warning_amber_rounded,
      HealthConnectStepsState.unsupportedPlatform =>
        Icons.phone_android_rounded,
      HealthConnectStepsState.error => Icons.error_outline_rounded,
      null => Icons.favorite_border_rounded,
    };
  }

  Color get _statusColor {
    return switch (_result?.state) {
      HealthConnectStepsState.ready => const Color(0xFF4CAF72),
      HealthConnectStepsState.permissionDenied => const Color(0xFFF4A340),
      HealthConnectStepsState.error => const Color(0xFFE45C6A),
      _ => const Color(0xFF5A8DEE),
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = _remainingSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          '리듬산책',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildStepsCard(now, remaining),
          const SizedBox(height: 16),
          _buildHealthConnectCard(),
          const SizedBox(height: 14),
          _buildInfoCard(),
          const SizedBox(height: 14),
          _buildCheerCard(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 184,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _HeroLandscapePainter()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 23, 12, 18),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              height: 1.08,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                            children: [
                              TextSpan(
                                text: '보미와 함께\n',
                                style: TextStyle(color: AppColors.navy),
                              ),
                              TextSpan(
                                text: '리듬산책',
                                style: TextStyle(color: _pink),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '오늘의 걸음 수를 확인하고\n'
                          '천천히 목표를 채워봐요.',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/bomi/bomi_walk.png',
                        height: 124,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard(DateTime now, int? remaining) {
    final steps = _result?.isReady == true ? _displaySteps : null;
    final progressPercent = (_displayProgress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5EBF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '오늘의 걸음 수',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${now.month}월 ${now.day}일',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                steps == null ? '-' : _formatNumber(steps),
                style: const TextStyle(
                  color: _pink,
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 3),
                child: Text(
                  '걸음',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '목표',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                  ),
                  Text(
                    '5,000걸음',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _displayProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF7DFE8),
              valueColor: const AlwaysStoppedAnimation<Color>(_pink),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              steps == null ? '-' : '$progressPercent%',
              style: const TextStyle(
                color: _pink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _buildRhythmPath(),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _softPink,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: _pink, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    steps == null
                        ? 'Health Connect에서 오늘 걸음 수를 확인해보세요.'
                        : remaining == 0
                        ? '오늘의 5,000걸음 목표를 채웠어요!'
                        : '목표까지 ${_formatNumber(remaining!)}걸음 남았어요.',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhythmPath() {
    return SizedBox(
      height: 126,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, 126);
          final point = _rhythmPoint(size, _displayProgress);

          final maxLeft = math.max(0.0, constraints.maxWidth - 54);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ?? ?? ??
              Positioned(
                left: 0,
                top: 2,
                width: 64,
                height: 70,
                child: Image.asset(
                  'assets/images/bomi/walk_tree_small.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: 45,
                top: 25,
                width: 32,
                height: 23,
                child: Image.asset(
                  'assets/images/bomi/walk_bush.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: 6,
                top: 26,
                width: 46,
                height: 32,
                child: Image.asset(
                  'assets/images/bomi/walk_bush.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: 45,
                top: 1,
                width: 60,
                height: 44,
                child: Image.asset(
                  'assets/images/bomi/walk_bench.png',
                  fit: BoxFit.contain,
                ),
              ),

              // ?? ?? ?? ??
              Positioned.fill(
                child: CustomPaint(
                  painter: _RhythmPathPainter(progress: _displayProgress),
                ),
              ),

              // ?? ?? ??
              Positioned(
                left: 13,
                bottom: 12,
                width: 45,
                height: 40,
                child: Image.asset(
                  'assets/images/bomi/walk_tulip.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: 48,
                bottom: 3,
                width: 25,
                height: 21,
                child: Image.asset(
                  'assets/images/bomi/walk_daisy.png',
                  fit: BoxFit.contain,
                ),
              ),

              // ?? ?? ??
              Positioned(
                left: 88,
                bottom: 1,
                width: 58,
                height: 30,
                child: Image.asset(
                  'assets/images/bomi/walk_flower_patch.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: 140,
                bottom: 15,
                width: 27,
                height: 23,
                child: Image.asset(
                  'assets/images/bomi/walk_daisy.png',
                  fit: BoxFit.contain,
                ),
              ),

              // ??? ?? ??
              Positioned(
                right: 73,
                bottom: 3,
                width: 44,
                height: 24,
                child: Image.asset(
                  'assets/images/bomi/walk_flower_patch.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: 27,
                bottom: 15,
                width: 35,
                height: 32,
                child: Image.asset(
                  'assets/images/bomi/walk_tulip.png',
                  fit: BoxFit.contain,
                ),
              ),

              Positioned(
                left: (point.dx - 34).clamp(0.0, maxLeft).toDouble(),
                top: (point.dy - 58).clamp(0.0, 68.0).toDouble(),
                width: 68,
                height: 68,
                child: Image.asset(
                  'assets/images/bomi/bomi_walk_progress.png',
                  fit: BoxFit.contain,
                ),
              ),
              const Positioned(
                left: 0,
                bottom: 0,
                child: Text(
                  '시작',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Image.asset(
                      'assets/images/bomi/walk_goal_gift.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '5,000걸음',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHealthConnectCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_statusIcon, color: _statusColor, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusTitle,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                    if (_lastUpdatedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '마지막 업데이트  '
                        '${_twoDigits(_lastUpdatedAt!.hour)}:'
                        '${_twoDigits(_lastUpdatedAt!.minute)}',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _loading ? null : _loadSteps,
              style: FilledButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF7B6CA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(
                _result?.isReady == true
                    ? Icons.refresh_rounded
                    : Icons.sync_rounded,
              ),
              label: Text(
                _buttonText,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _pink, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '걸음 수는 Health Connect에서 가져와요. '
              '직접 입력한 걸음 기록은 포함하지 않아요.',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheerCard() {
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F6), Color(0xFFFFF9FB)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Image.asset(
              'assets/images/bomi/bomi_reward_success.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보미가 응원해요!',
                  style: TextStyle(
                    color: _pink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '한 걸음씩 천천히, '
                  '오늘의 건강 습관을 채워봐요.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11.5,
                    height: 1.4,
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

class _HeroLandscapePainter extends CustomPainter {
  const _HeroLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFECF3), Color(0xFFF7F3FC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, background);

    final hillPaint = Paint()..color = const Color(0xFFDFF3D9);
    final hillPath = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.52,
        size.width * 0.5,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.82,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(hillPath, hillPaint);

    final pathPaint = Paint()
      ..color = const Color(0xFFFFF7EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final walkPath = Path()
      ..moveTo(size.width * 0.47, size.height)
      ..cubicTo(
        size.width * 0.56,
        size.height * 0.68,
        size.width * 0.76,
        size.height * 0.82,
        size.width * 0.98,
        size.height * 0.48,
      );

    canvas.drawPath(walkPath, pathPaint);

    final flowerPaint = Paint()..color = const Color(0xFFFFB7CC);
    for (final point in <Offset>[
      Offset(size.width * 0.10, size.height * 0.82),
      Offset(size.width * 0.22, size.height * 0.73),
      Offset(size.width * 0.88, size.height * 0.78),
      Offset(size.width * 0.94, size.height * 0.66),
    ]) {
      canvas.drawCircle(point, 4, flowerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroLandscapePainter oldDelegate) => false;
}

class _RhythmPathPainter extends CustomPainter {
  const _RhythmPathPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _rhythmPath(size);

    final basePaint = Paint()
      ..color = const Color(0xFFE2E8F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFFF77B9E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, basePaint);

    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final progressPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(progressPath, progressPaint);
    }

    final nodeFill = Paint()..color = Colors.white;
    final nodeBorder = Paint()
      ..color = const Color(0xFFF3A0B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final t in <double>[0, 0.33, 0.66, 1]) {
      final point = _rhythmPoint(size, t);
      canvas.drawCircle(point, 6, nodeFill);
      canvas.drawCircle(point, 6, nodeBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmPathPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

Path _rhythmPath(Size size) {
  final width = size.width;

  // ?? ??? ??? ???? ??? ?? ??? ???.
  return Path()
    ..moveTo(18, 92)
    ..cubicTo(width * 0.10, 42, width * 0.26, 38, width * 0.32, 76)
    ..cubicTo(width * 0.39, 122, width * 0.54, 121, width * 0.60, 78)
    ..cubicTo(width * 0.67, 30, width * 0.82, 42, width - 18, 84);
}

Offset _rhythmPoint(Size size, double progress) {
  final path = _rhythmPath(size);
  final metrics = path.computeMetrics().toList();

  if (metrics.isEmpty) {
    return const Offset(18, 92);
  }

  final metric = metrics.first;
  final safeProgress = progress.clamp(0.0, 1.0).toDouble();

  final tangent = metric.getTangentForOffset(metric.length * safeProgress);

  return tangent?.position ?? const Offset(18, 92);
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;

    buffer.write(text[i]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
