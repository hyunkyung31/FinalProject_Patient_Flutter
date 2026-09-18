import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/health_mission.dart';
import '../model/health_quiz.dart';
import '../repository/health_mission_repository.dart';

class HealthQuizScreenResult {
  const HealthQuizScreenResult({
    required this.alreadyCompleted,
    this.awardedPoints,
  });

  final bool alreadyCompleted;
  final double? awardedPoints;
}

class HealthQuizScreen extends StatefulWidget {
  const HealthQuizScreen({
    super.key,
    required this.repository,
    required this.mission,
  });

  final HealthMissionRepository repository;
  final PatientHealthMission mission;

  @override
  State<HealthQuizScreen> createState() => _HealthQuizScreenState();
}

class _HealthQuizScreenState extends State<HealthQuizScreen> {
  HealthQuiz? _quiz;
  String? _selectedAnswerId;
  String? _explanation;
  String? _error;

  bool _loading = true;
  bool _submitting = false;
  bool _correct = false;
  bool _completed = false;
  bool _alreadyCompleted = false;

  double? _awardedPoints;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final quiz = await widget.repository.getDailyQuiz(widget.mission.id);

      if (!mounted) return;

      setState(() {
        _quiz = quiz;
        _alreadyCompleted = quiz.alreadyCompleted;
        _completed = quiz.alreadyCompleted;
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

  void _selectAnswer(String answerId) {
    if (_submitting || _correct || _completed) return;

    setState(() {
      _selectedAnswerId = answerId;
    });
  }

  Future<void> _submitAnswer() async {
    final quiz = _quiz;
    final answerId = _selectedAnswerId;

    if (quiz == null || answerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정답이라고 생각하는 보기를 선택해 주세요.')));
      return;
    }

    if (_submitting || _completed) return;

    setState(() {
      _submitting = true;
    });

    try {
      final answerResult = await widget.repository.submitDailyQuizAnswer(
        missionId: widget.mission.id,
        answerId: answerId,
      );

      if (!mounted) return;

      if (!answerResult.isCorrect) {
        setState(() {
          _submitting = false;
        });

        await _showRetryDialog();

        if (!mounted) return;

        setState(() {
          _selectedAnswerId = null;
        });
        return;
      }

      setState(() {
        _correct = true;
        _explanation = answerResult.explanation;
      });

      final completion = await widget.repository.completeMission(
        widget.mission.id,
      );

      if (!mounted) return;

      setState(() {
        _submitting = false;
        _completed = true;
        _alreadyCompleted = completion.alreadyCompleted;
        _awardedPoints = completion.awardedPoints;
      });

      await _finishQuiz();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(healthMissionErrorMessage(error))));
    }
  }

  Future<void> _showRetryDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDF3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '다시 도전!',
                    style: TextStyle(
                      color: Color(0xFFE85D8C),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '조금만 더 생각해볼까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '괜찮아요. 다시 풀어보면 충분히 맞힐 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const _AnimatedBomi(
                  assetPath: 'assets/images/bomi/bomi_quiz_retry.png',
                  size: 190,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '한 번 더 도전하기',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCorrectDialog() async {
    final awardedPoints = _awardedPoints;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF9F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '정답이에요!',
                    style: TextStyle(
                      color: Color(0xFF2E9B62),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const _AnimatedBomi(
                  assetPath: 'assets/images/bomi/bomi_quiz_correct.png',
                  size: 190,
                ),
                const SizedBox(height: 2),
                const Text(
                  '잘했어요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                if (awardedPoints != null)
                  Text(
                    '정답 보상 +${_pointText(awardedPoints)}P',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE85D8C),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                if (_explanation != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          color: Color(0xFFFFB02E),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _explanation!,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '보상 확인하기',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRewardDialog(double awardedPoints) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF2F7), Colors.white],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '오늘의 퀴즈 완료!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const _RewardBurst(
                  child: _AnimatedBomi(
                    assetPath: 'assets/images/bomi/bomi_quiz_reward.png',
                    size: 205,
                  ),
                ),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.72, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Text(
                    '+${_pointText(awardedPoints)}P',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE85D8C),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '포인트 적립 완료',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '오늘도 건강 지식을 하나 더 채웠어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _finishQuiz() async {
    // 정답을 맞힌 순간과 보상을 확인하는 순간을 분리해서 보여줍니다.
    if (_correct) {
      await _showCorrectDialog();

      if (!mounted) return;
    }

    final awardedPoints = _awardedPoints;

    if (awardedPoints != null && !_alreadyCompleted) {
      await _showRewardDialog(awardedPoints);

      if (!mounted) return;
    }

    _close();
  }

  void _close() {
    Navigator.of(context).pop<HealthQuizScreenResult>(
      HealthQuizScreenResult(
        alreadyCompleted: _alreadyCompleted,
        awardedPoints: _awardedPoints,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          '1분 건강퀴즈',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _QuizErrorState(message: _error!, onRetry: _loadQuiz);
    }

    final quiz = _quiz;

    if (quiz == null) {
      return const Center(child: Text('오늘의 건강퀴즈를 불러오지 못했어요.'));
    }

    if (_alreadyCompleted && !_correct) {
      return _AlreadyCompletedState(onClose: _close);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QuizHeaderCard(rewardPoints: quiz.rewardPoints),
            const SizedBox(height: 20),
            _QuestionCard(question: quiz.question.question),
            const SizedBox(height: 16),
            ...quiz.question.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AnswerCard(
                  option: option,
                  selected: _selectedAnswerId == option.id,
                  disabled: _submitting || _correct || _completed,
                  onTap: () => _selectAnswer(option.id),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_completed)
              FilledButton(
                onPressed: _finishQuiz,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _awardedPoints == null
                      ? '완료'
                      : '완료 · +${_pointText(_awardedPoints!)}P',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              FilledButton(
                onPressed: _selectedAnswerId == null || _submitting
                    ? null
                    : _submitAnswer,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '정답 확인하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizHeaderCard extends StatelessWidget {
  const _QuizHeaderCard({required this.rewardPoints});

  final int rewardPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEF4), Color(0xFFFFF7FA)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 165,
            height: 145,
            child: Image(
              image: AssetImage('assets/images/bomi/bomi_quiz_thinking.png'),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 한 문제',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '가볍게 건강 상식을 확인해 보세요.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                if (rewardPoints > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '정답 시 +${rewardPoints}P',
                      style: const TextStyle(
                        color: Color(0xFFE85D8C),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Text(
        question,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          height: 1.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.option,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final HealthQuizOption option;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.navy : const Color(0xFFE1E7F0);

    return Material(
      color: selected ? const Color(0xFFF1F5FF) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : const Color(0xFFF3F6FA),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  option.id,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardBurst extends StatefulWidget {
  const _RewardBurst({required this.child});

  final Widget child;

  @override
  State<_RewardBurst> createState() => _RewardBurstState();
}

class _RewardBurstState extends State<_RewardBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  int _burstCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _playBursts();
  }

  Future<void> _playBursts() async {
    while (mounted && _burstCount < 3) {
      _burstCount += 1;

      await _controller.forward(from: 0);

      if (!mounted || _burstCount >= 3) return;

      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 220,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final value = _controller.value;

          final opacity = value < 0.72
              ? 1.0
              : ((1 - value) / 0.28).clamp(0.0, 1.0).toDouble();

          Widget particle({
            required IconData icon,
            required double dx,
            required double dy,
            required double size,
            required Color color,
          }) {
            return Transform.translate(
              offset: Offset(dx * value, dy * value),
              child: Transform.rotate(
                angle: value * 1.4,
                child: Opacity(
                  opacity: opacity,
                  child: Icon(icon, size: size, color: color),
                ),
              ),
            );
          }

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              particle(
                icon: Icons.favorite_rounded,
                dx: -86,
                dy: -62,
                size: 19,
                color: const Color(0xFFFF7FA6),
              ),
              particle(
                icon: Icons.star_rounded,
                dx: 82,
                dy: -68,
                size: 22,
                color: const Color(0xFFFFC247),
              ),
              particle(
                icon: Icons.circle,
                dx: -96,
                dy: 12,
                size: 10,
                color: const Color(0xFF61B9F5),
              ),
              particle(
                icon: Icons.favorite_rounded,
                dx: 92,
                dy: 18,
                size: 15,
                color: const Color(0xFFFF91B4),
              ),
              particle(
                icon: Icons.star_rounded,
                dx: -66,
                dy: 70,
                size: 17,
                color: const Color(0xFFFFD462),
              ),
              particle(
                icon: Icons.circle,
                dx: 70,
                dy: 72,
                size: 9,
                color: const Color(0xFF7ED7C4),
              ),
              particle(
                icon: Icons.favorite_rounded,
                dx: -22,
                dy: -92,
                size: 14,
                color: const Color(0xFFFF92AC),
              ),
              particle(
                icon: Icons.star_rounded,
                dx: 30,
                dy: -94,
                size: 15,
                color: const Color(0xFFFFC84D),
              ),
              child!,
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedBomi extends StatefulWidget {
  const _AnimatedBomi({required this.assetPath, required this.size});

  final String assetPath;
  final double size;

  @override
  State<_AnimatedBomi> createState() => _AnimatedBomiState();
}

class _AnimatedBomiState extends State<_AnimatedBomi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat(reverse: true);

    _moveAnimation = Tween<double>(
      begin: 2,
      end: -7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        child: Image.asset(widget.assetPath, fit: BoxFit.contain),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _moveAnimation.value),
            child: Transform.scale(
              scale: 0.985 + (_controller.value * 0.025),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _AlreadyCompletedState extends StatelessWidget {
  const _AlreadyCompletedState({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/bomi/bomi_12_celebration.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            const Text(
              '오늘 퀴즈는 이미 완료했어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '내일 새로운 건강 상식으로 다시 만나요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onClose, child: const Text('돌아가기')),
          ],
        ),
      ),
    );
  }
}

class _QuizErrorState extends StatelessWidget {
  const _QuizErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText, height: 1.5),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

String _pointText(double points) {
  if (points == points.roundToDouble()) {
    return points.toInt().toString();
  }

  return points.toStringAsFixed(1);
}
