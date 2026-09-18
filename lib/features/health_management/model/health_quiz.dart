class HealthQuizOption {
  const HealthQuizOption({required this.id, required this.text});

  final String id;
  final String text;

  factory HealthQuizOption.fromJson(Map<String, dynamic> json) {
    return HealthQuizOption(
      id: _requiredString(json['id'], 'quiz_option.id'),
      text: _requiredString(json['text'], 'quiz_option.text'),
    );
  }
}

class HealthQuizQuestion {
  const HealthQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  final String id;
  final String question;
  final List<HealthQuizOption> options;

  factory HealthQuizQuestion.fromJson(Map<String, dynamic> json) {
    final optionData = json['options'];

    if (optionData is! List) {
      throw const FormatException('건강퀴즈 보기 형식이 올바르지 않습니다.');
    }

    final options = optionData
        .whereType<Map>()
        .map(
          (item) => HealthQuizOption.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    if (options.length != 4) {
      throw const FormatException('건강퀴즈 보기 개수가 올바르지 않습니다.');
    }

    return HealthQuizQuestion(
      id: _requiredString(json['id'], 'quiz_question.id'),
      question: _requiredString(json['question'], 'quiz_question.question'),
      options: options,
    );
  }
}

class HealthQuiz {
  const HealthQuiz({
    required this.missionId,
    required this.question,
    required this.rewardPoints,
    required this.alreadyCompleted,
  });

  final int missionId;
  final HealthQuizQuestion question;
  final int rewardPoints;
  final bool alreadyCompleted;

  factory HealthQuiz.fromJson(Map<String, dynamic> json) {
    final questionData = json['question'];

    if (questionData is! Map) {
      throw const FormatException('건강퀴즈 문제 형식이 올바르지 않습니다.');
    }

    return HealthQuiz(
      missionId: _requiredInt(json['mission_id'], 'mission_id'),
      question: HealthQuizQuestion.fromJson(
        Map<String, dynamic>.from(questionData),
      ),
      rewardPoints: _intOrZero(json['reward_points']),
      alreadyCompleted: json['already_completed'] == true,
    );
  }
}

class HealthQuizAnswerResult {
  const HealthQuizAnswerResult({
    required this.isCorrect,
    required this.questionId,
    required this.targetReached,
    this.message,
    this.explanation,
    this.progressValue,
    this.targetValue,
  });

  final bool isCorrect;
  final String questionId;
  final String? message;
  final String? explanation;
  final double? progressValue;
  final double? targetValue;
  final bool targetReached;

  factory HealthQuizAnswerResult.fromJson(Map<String, dynamic> json) {
    return HealthQuizAnswerResult(
      isCorrect: json['is_correct'] == true,
      questionId: _requiredString(json['question_id'], 'question_id'),
      message: _optionalString(json['message']),
      explanation: _optionalString(json['explanation']),
      progressValue: _optionalDouble(json['progress_value']),
      targetValue: _optionalDouble(json['target_value']),
      targetReached: json['target_reached'] == true,
    );
  }
}

String _requiredString(Object? value, String field) {
  final result = _optionalString(value);

  if (result == null) {
    throw FormatException('$field 값이 올바르지 않습니다.');
  }

  return result;
}

String? _optionalString(Object? value) {
  if (value == null) return null;

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _requiredInt(Object? value, String field) {
  final parsed = _optionalInt(value);

  if (parsed == null) {
    throw FormatException('$field 값이 올바르지 않습니다.');
  }

  return parsed;
}

int _intOrZero(Object? value) {
  return _optionalInt(value) ?? 0;
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}

double? _optionalDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString());
}
