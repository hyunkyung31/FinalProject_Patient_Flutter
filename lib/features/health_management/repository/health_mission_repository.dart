import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../model/health_mission.dart';
import '../model/health_quiz.dart';

abstract class HealthMissionRepository {
  Future<List<PatientHealthMission>> getMissions({
    String? status,
    DateTime? date,
  });

  Future<List<PatientHealthMission>> getTodayMissions();

  Future<HealthQuiz> getDailyQuiz(int missionId);

  Future<HealthQuizAnswerResult> submitDailyQuizAnswer({
    required int missionId,
    required String answerId,
  });

  Future<HealthMissionLog> saveMissionLog({
    required int missionId,
    required DateTime activityDate,
    double? achievedValue,
    String? note,
  });

  Future<HealthMissionCompletion> completeMission(int missionId);
}

class PatientHealthMissionRepository implements HealthMissionRepository {
  PatientHealthMissionRepository(this.client);

  final ApiClient client;

  static const _path = '/api/patient/health-missions/';

  @override
  Future<List<PatientHealthMission>> getMissions({
    String? status,
    DateTime? date,
  }) async {
    final query = <String, dynamic>{};

    final normalizedStatus = status?.trim();
    if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
      query['status'] = normalizedStatus;
    }

    if (date != null) {
      query['date'] = _dateText(date);
    }

    final response = await client.dio.get<Object?>(
      _path,
      queryParameters: query.isEmpty ? null : query,
    );

    return _parseMissionList(response.data);
  }

  @override
  Future<List<PatientHealthMission>> getTodayMissions() async {
    final response = await client.dio.get<Object?>('${_path}today/');

    return _parseMissionList(response.data);
  }

  @override
  Future<HealthQuiz> getDailyQuiz(int missionId) async {
    final response = await client.dio.get<Object?>('$_path$missionId/quiz/');

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('건강퀴즈 응답이 올바르지 않습니다.');
    }

    return HealthQuiz.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<HealthQuizAnswerResult> submitDailyQuizAnswer({
    required int missionId,
    required String answerId,
  }) async {
    final response = await client.dio.post<Object?>(
      '$_path$missionId/quiz/',
      data: <String, dynamic>{'answer_id': answerId},
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('건강퀴즈 답안 응답이 올바르지 않습니다.');
    }

    return HealthQuizAnswerResult.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<HealthMissionLog> saveMissionLog({
    required int missionId,
    required DateTime activityDate,
    double? achievedValue,
    String? note,
  }) async {
    final normalizedNote = note?.trim();

    final payload = <String, dynamic>{'activity_date': _dateText(activityDate)};

    if (achievedValue != null) {
      payload['achieved_value'] = achievedValue;
    }

    if (normalizedNote != null && normalizedNote.isNotEmpty) {
      payload['note'] = normalizedNote;
    }

    final response = await client.dio.post<Object?>(
      '$_path$missionId/logs/',
      data: payload,
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('건강 미션 수행 기록 응답이 올바르지 않습니다.');
    }

    return HealthMissionLog.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<HealthMissionCompletion> completeMission(int missionId) async {
    final response = await client.dio.post<Object?>(
      '$_path$missionId/complete/',
      data: const <String, dynamic>{},
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('건강 미션 완료 응답이 올바르지 않습니다.');
    }

    return HealthMissionCompletion.fromJson(Map<String, dynamic>.from(data));
  }

  List<PatientHealthMission> _parseMissionList(Object? data) {
    if (data is! List) {
      throw const FormatException('건강 미션 목록 형식이 올바르지 않습니다.');
    }

    return data
        .whereType<Map>()
        .map(
          (item) =>
              PatientHealthMission.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}

String healthMissionErrorMessage(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      400 => '건강 미션 입력 내용을 확인해 주세요.',
      401 => '로그인이 만료됐어요. 다시 로그인해 주세요.',
      403 => '이 건강 미션에 접근할 권한이 없어요.',
      404 => '건강 미션을 찾을 수 없어요.',
      409 => '아직 미션을 완료할 수 없어요. 진행 상태를 확인해 주세요.',
      _ => '건강 미션 정보를 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
    };
  }

  if (error is FormatException) {
    return error.message;
  }

  return '건강 미션 정보를 처리하지 못했어요. 다시 시도해 주세요.';
}
