import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../model/reward.dart';

abstract class RewardRepository {
  Future<PointAccount> getPointAccount();

  Future<List<PointTransaction>> getPointTransactions({
    String? type,
    DateTime? date,
  });

  Future<RewardOverview> getRewards({bool? available, bool? acquired});

  Future<RewardRedeemResult> redeemReward({
    required int rewardId,
    required String idempotencyKey,
  });
}

class PatientRewardRepository implements RewardRepository {
  PatientRewardRepository(this.client);

  final ApiClient client;

  static const _pointsPath = '/api/patient/points/';
  static const _transactionsPath = '/api/patient/point-transactions/';
  static const _rewardsPath = '/api/patient/rewards/';

  @override
  Future<PointAccount> getPointAccount() async {
    final response = await client.dio.get<Object?>(_pointsPath);

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('포인트 계정 응답 형식이 올바르지 않습니다.');
    }

    return PointAccount.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<PointTransaction>> getPointTransactions({
    String? type,
    DateTime? date,
  }) async {
    final query = <String, dynamic>{};

    final normalizedType = type?.trim().toUpperCase();

    if (normalizedType != null && normalizedType.isNotEmpty) {
      query['type'] = normalizedType;
    }

    if (date != null) {
      query['date'] = _dateText(date);
    }

    final response = await client.dio.get<Object?>(
      _transactionsPath,
      queryParameters: query.isEmpty ? null : query,
    );

    final data = response.data;

    if (data is! List) {
      throw const FormatException('포인트 거래 내역 응답 형식이 올바르지 않습니다.');
    }

    return data
        .whereType<Map>()
        .map(
          (item) => PointTransaction.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<RewardOverview> getRewards({bool? available, bool? acquired}) async {
    final query = <String, dynamic>{};

    if (available != null) {
      query['available'] = available;
    }

    if (acquired != null) {
      query['acquired'] = acquired;
    }

    final response = await client.dio.get<Object?>(
      _rewardsPath,
      queryParameters: query.isEmpty ? null : query,
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('리워드 목록 응답 형식이 올바르지 않습니다.');
    }

    return RewardOverview.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<RewardRedeemResult> redeemReward({
    required int rewardId,
    required String idempotencyKey,
  }) async {
    final normalizedKey = idempotencyKey.trim();

    if (normalizedKey.isEmpty) {
      throw const FormatException('리워드 교환 요청 키가 필요합니다.');
    }

    final response = await client.dio.post<Object?>(
      '$_rewardsPath$rewardId/redeem/',
      data: <String, dynamic>{'idempotency_key': normalizedKey},
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('리워드 교환 응답 형식이 올바르지 않습니다.');
    }

    return RewardRedeemResult.fromJson(Map<String, dynamic>.from(data));
  }

  String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}

String rewardErrorMessage(Object error) {
  if (error is DioException) {
    final detail = _responseDetail(error.response?.data);

    if (detail != null) {
      return detail;
    }

    return switch (error.response?.statusCode) {
      400 => '리워드 요청 내용을 확인해 주세요.',
      401 => '로그인이 만료됐어요. 다시 로그인해 주세요.',
      403 => '리워드 정보에 접근할 권한이 없어요.',
      404 => '현재 교환할 수 있는 리워드를 찾을 수 없어요.',
      409 => '현재 리워드를 교환할 수 없어요.',
      _ => '리워드 정보를 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
    };
  }

  if (error is FormatException) {
    return error.message;
  }

  return '리워드 정보를 처리하지 못했어요. 다시 시도해 주세요.';
}

String? _responseDetail(Object? data) {
  if (data is! Map) {
    return null;
  }

  final detail = data['detail'];

  if (detail is! String || detail.trim().isEmpty) {
    return null;
  }

  return detail.trim();
}
