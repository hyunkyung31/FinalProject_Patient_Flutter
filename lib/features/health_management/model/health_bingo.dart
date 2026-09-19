class HealthBingoCell {
  const HealthBingoCell({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.completed,
    this.completedAt,
  });

  final String code;
  final String title;
  final String description;
  final String icon;
  final bool completed;
  final DateTime? completedAt;

  factory HealthBingoCell.fromJson(Map<String, dynamic> json) {
    final completedAtRaw = json['completed_at'];

    return HealthBingoCell(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      completedAt: completedAtRaw is String
          ? DateTime.tryParse(completedAtRaw)
          : null,
    );
  }
}

class HealthBingoBoard {
  const HealthBingoBoard({
    required this.missionId,
    required this.title,
    required this.startsOn,
    required this.endsOn,
    required this.rewardPoints,
    required this.targetLines,
    required this.lineCount,
    required this.completedLines,
    required this.cells,
    required this.goalReached,
    required this.alreadyCompleted,
    this.rewardPerLine = 0,
    this.maxLines = 0,
    this.rewardedLineCount = 0,
    this.newlyAwardedLines = 0,
    this.newlyAwardedPoints = 0,
    this.totalRewardedPoints = 0,
    this.cellCreated,
  });

  final int missionId;
  final String title;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final int rewardPoints;
  final int targetLines;
  final int lineCount;
  final List<List<String>> completedLines;
  final List<HealthBingoCell> cells;
  final bool goalReached;
  final bool alreadyCompleted;

  // 한 줄당 지급되는 빙고 보상 포인트
  final int rewardPerLine;

  // 3x3 빙고에서 인정할 수 있는 전체 줄 수
  final int maxLines;

  // 현재까지 포인트가 지급된 빙고 줄 수
  final int rewardedLineCount;

  // 이번 조회에서 새로 보상된 줄 수
  final int newlyAwardedLines;

  // 이번 조회에서 새로 적립된 포인트
  final int newlyAwardedPoints;

  // 이번 주 빙고로 지금까지 받은 누적 포인트
  final int totalRewardedPoints;

  final bool? cellCreated;

  factory HealthBingoBoard.fromJson(Map<String, dynamic> json) {
    final startsOnRaw = json['starts_on'];
    final endsOnRaw = json['ends_on'];

    final completedLinesRaw = json['completed_lines'];

    final cellsRaw = json['cells'];

    return HealthBingoBoard(
      missionId: _toInt(json['mission_id']),
      title: json['title'] as String? ?? '',
      startsOn: startsOnRaw is String ? DateTime.tryParse(startsOnRaw) : null,
      endsOn: endsOnRaw is String ? DateTime.tryParse(endsOnRaw) : null,
      rewardPoints: _toInt(json['reward_points']),
      targetLines: _toInt(json['target_lines']),
      lineCount: _toInt(json['line_count']),
      completedLines: completedLinesRaw is List
          ? completedLinesRaw
                .whereType<List>()
                .map((line) => line.whereType<String>().toList())
                .toList()
          : const <List<String>>[],
      cells: cellsRaw is List
          ? cellsRaw
                .whereType<Map>()
                .map(
                  (cell) =>
                      HealthBingoCell.fromJson(Map<String, dynamic>.from(cell)),
                )
                .toList()
          : const <HealthBingoCell>[],
      goalReached: json['goal_reached'] as bool? ?? false,
      alreadyCompleted: json['already_completed'] as bool? ?? false,
      rewardPerLine: _toInt(json['reward_per_line'] ?? json['reward_points']),
      maxLines: _toInt(json['max_lines']),
      rewardedLineCount: _toInt(json['rewarded_line_count']),
      newlyAwardedLines: _toInt(json['newly_awarded_lines']),
      newlyAwardedPoints: _toInt(json['newly_awarded_points']),
      totalRewardedPoints: _toInt(json['total_rewarded_points']),
      cellCreated: json['cell_created'] as bool?,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
