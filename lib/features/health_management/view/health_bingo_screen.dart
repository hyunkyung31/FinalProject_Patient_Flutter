import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/health_bingo.dart';
import '../model/health_mission.dart';
import '../repository/health_mission_repository.dart';

class HealthBingoScreenResult {
  const HealthBingoScreenResult({required this.completed, this.awardedPoints});

  final bool completed;
  final double? awardedPoints;
}

class HealthBingoScreen extends StatefulWidget {
  const HealthBingoScreen({
    super.key,
    required this.repository,
    required this.mission,
  });

  final HealthMissionRepository repository;
  final PatientHealthMission mission;

  @override
  State<HealthBingoScreen> createState() => _HealthBingoScreenState();
}

class _HealthBingoScreenState extends State<HealthBingoScreen> {
  HealthBingoBoard? _board;

  bool _loading = true;
  bool _missionCompleted = false;

  String? _error;
  double? _awardedPoints;

  @override
  void initState() {
    super.initState();
    _missionCompleted = widget.mission.status == 'COMPLETED';
    _loadBingo();
  }

  Future<void> _loadBingo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 빙고 조회 API가 원본 건강활동을 동기화하고
      // 새로 완성된 줄의 포인트까지 자동으로 지급한다.
      final board = await widget.repository.getWeeklyBingo(widget.mission.id);

      if (!mounted) return;

      final newPoints = board.newlyAwardedPoints;

      setState(() {
        _board = board;
        _missionCompleted = board.alreadyCompleted || board.lineCount > 0;
        _loading = false;

        if (newPoints > 0) {
          _awardedPoints = (_awardedPoints ?? 0) + newPoints.toDouble();
        }
      });

      // idempotency가 적용된 서버 응답이므로
      // 이번 조회에서 실제 새 보상이 생긴 경우에만 보여준다.
      if (newPoints > 0) {
        await _showRewardDialog(
          lines: board.newlyAwardedLines,
          points: newPoints,
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = healthMissionErrorMessage(error);
      });
    }
  }

  Future<void> _showRewardDialog({
    required int lines,
    required int points,
  }) async {
    final title = lines <= 1 ? '빙고 한 줄 완성!' : '빙고 $lines줄 추가 완성!';

    final message = lines <= 1
        ? '건강한 실천이 한 줄의 빙고로 이어졌어요.'
        : '이번 활동으로 새로운 빙고 $lines줄이 완성됐어요.';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDCEBFF), Color(0xFFE9E5FF)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/bomi/bomi_quiz_reward.png',
                  width: 185,
                  height: 185,
                  fit: BoxFit.contain,
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.75, end: 1),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Text(
                    '+${_pointText(points.toDouble())}P',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _close() {
    Navigator.of(context).pop(
      HealthBingoScreenResult(
        completed: _missionCompleted,
        awardedPoints: _awardedPoints,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          '두근빙고',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          onPressed: _close,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navy,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _BingoErrorState(message: _error!, onRetry: _loadBingo);
    }

    final board = _board;

    if (board == null) {
      return const Center(child: Text('이번 주 두근빙고를 불러오지 못했어요.'));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BingoHeroCard(board: board, completed: _missionCompleted),
            const SizedBox(height: 18),
            _BingoBoardCard(board: board),
            const SizedBox(height: 16),
            _BingoProgressCard(
              board: board,
              missionCompleted: _missionCompleted,
            ),
          ],
        ),
      ),
    );
  }
}

class _BingoHeroCard extends StatelessWidget {
  const _BingoHeroCard({required this.board, required this.completed});

  final HealthBingoBoard board;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final maxLines = board.maxLines > 0 ? board.maxLines : 8;

    return Container(
      height: 146,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCEBFF), Color(0xFFE9E5FF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 17,
            right: 116,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  board.lineCount > 0
                      ? '이번 주 ${board.lineCount}줄 완성!'
                      : '건강한 하루가\n빙고 한 칸이 돼요',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    height: 1.28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  board.lineCount > 0
                      ? '아직 끝이 아니에요. 최대 $maxLines줄까지 계속 도전해보세요.'
                      : '건강활동을 완료하면 빙고가 자동으로 채워져요.',
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11.7,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _dateRangeText(board.startsOn, board.endsOn),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 3,
            bottom: 1,
            child: SizedBox(
              width: 116,
              height: 130,
              child: Image.asset(
                completed
                    ? 'assets/images/bomi/bomi_quiz_correct.png'
                    : 'assets/images/bomi/bomi_quiz_thinking.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BingoBoardCard extends StatelessWidget {
  const _BingoBoardCard({required this.board});

  final HealthBingoBoard board;

  @override
  Widget build(BuildContext context) {
    final completedCount = board.cells.where((cell) => cell.completed).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101E3A8A),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이번 주 빙고판',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '건강활동을 완료하면 자동으로 채워져요.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completedCount/${board.cells.length} 완료',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: board.cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 0.96,
            ),
            itemBuilder: (context, index) {
              return _BingoCellTile(cell: board.cells[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _BingoCellTile extends StatelessWidget {
  const _BingoCellTile({required this.cell});

  final HealthBingoCell cell;

  @override
  Widget build(BuildContext context) {
    final completed = cell.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: completed ? AppColors.softPink : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: completed ? AppColors.pink : const Color(0xFFE4EBF4),
          width: completed ? 1.5 : 1,
        ),
        boxShadow: completed
            ? const [
                BoxShadow(
                  color: Color(0x20F59CB3),
                  blurRadius: 9,
                  offset: Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: completed ? Colors.white : AppColors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconFor(cell.icon),
                    color: completed ? AppColors.navy : AppColors.blue,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  cell.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: completed ? AppColors.navy : AppColors.text,
                    fontSize: 11.2,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (completed)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.pink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BingoProgressCard extends StatelessWidget {
  const _BingoProgressCard({
    required this.board,
    required this.missionCompleted,
  });

  final HealthBingoBoard board;
  final bool missionCompleted;

  @override
  Widget build(BuildContext context) {
    final completedCount = board.cells.where((cell) => cell.completed).length;

    final totalCells = board.cells.isEmpty ? 1 : board.cells.length;

    final cellProgress = (completedCount / totalCells)
        .clamp(0.0, 1.0)
        .toDouble();

    final maxLines = board.maxLines > 0 ? board.maxLines : 8;

    final rewardPerLine = board.rewardPerLine > 0
        ? board.rewardPerLine
        : board.rewardPoints;

    final totalRewardedPoints = board.totalRewardedPoints > 0
        ? board.totalRewardedPoints
        : board.rewardedLineCount * rewardPerLine;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1E3A8A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: const BoxDecoration(
                  color: AppColors.softPink,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.navy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.lineCount > 0
                          ? '빙고를 계속 완성해보세요!'
                          : '첫 번째 빙고에 도전해보세요',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '한 줄 완성할 때마다 +${rewardPerLine}P',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '최대 $maxLines줄',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _BingoStatusBox(
                  label: '완성한 빙고',
                  value: '${board.lineCount}줄',
                  icon: Icons.emoji_events_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BingoStatusBox(
                  label: '누적 보상',
                  value: '+${totalRewardedPoints}P',
                  icon: Icons.stars_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                '완료한 건강활동',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount/${board.cells.length}칸',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: cellProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE9EEF5),
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            board.lineCount >= maxLines
                ? '이번 주 모든 빙고 라인을 완성했어요!'
                : '활동을 계속하면 새로운 빙고 줄도 자동으로 인정돼요.',
            style: TextStyle(
              color: board.lineCount >= maxLines
                  ? AppColors.pink
                  : AppColors.mutedText,
              fontSize: 10.8,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BingoStatusBox extends StatelessWidget {
  const _BingoStatusBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
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

class _BingoErrorState extends StatelessWidget {
  const _BingoErrorState({required this.message, required this.onRetry});

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
              color: AppColors.mutedText,
              size: 50,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText, height: 1.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String icon) {
  return switch (icon) {
    'favorite' => Icons.favorite_rounded,
    'air' => Icons.air_rounded,
    'quiz' => Icons.quiz_rounded,
    'directions_walk' => Icons.directions_walk_rounded,
    'accessibility_new' => Icons.accessibility_new_rounded,
    'eco' => Icons.eco_rounded,
    'directions_run' => Icons.directions_run_rounded,
    'menu_book' => Icons.menu_book_rounded,
    'bedtime' => Icons.bedtime_rounded,
    _ => Icons.favorite_border_rounded,
  };
}

String _dateRangeText(DateTime? startsOn, DateTime? endsOn) {
  if (startsOn == null || endsOn == null) {
    return '이번 주';
  }

  return '${_dateText(startsOn)} - ${_dateText(endsOn)}';
}

String _dateText(DateTime date) {
  return '${date.month}월 ${date.day}일';
}

String _pointText(double points) {
  if (points == points.roundToDouble()) {
    return points.toInt().toString();
  }

  return points.toStringAsFixed(1);
}
