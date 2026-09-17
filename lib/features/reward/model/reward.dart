class PointAccount {
  const PointAccount({
    required this.id,
    required this.patientAccount,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int patientAccount;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PointAccount.fromJson(Map<String, dynamic> json) {
    return PointAccount(
      id: _requiredInt(json['id'], 'id'),
      patientAccount: _requiredInt(json['patient_account'], 'patient_account'),
      balance: _requiredInt(json['balance'], 'balance'),
      totalEarned: _requiredInt(json['total_earned'], 'total_earned'),
      totalSpent: _requiredInt(json['total_spent'], 'total_spent'),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
    );
  }
}

class PointTransaction {
  const PointTransaction({
    required this.id,
    required this.pointAccount,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.occurredAt,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
    this.idempotencyKey,
  });

  final int id;
  final int pointAccount;
  final String transactionType;
  final int amount;
  final int balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String description;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String? idempotencyKey;

  bool get isEarned => transactionType.toUpperCase() == 'EARN';
  bool get isSpent => transactionType.toUpperCase() == 'SPEND';

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: _requiredInt(json['id'], 'id'),
      pointAccount: _requiredInt(json['point_account'], 'point_account'),
      transactionType: _requiredString(
        json['transaction_type'],
        'transaction_type',
      ),
      amount: _requiredInt(json['amount'], 'amount'),
      balanceAfter: _requiredInt(json['balance_after'], 'balance_after'),
      referenceType: _nullableString(json['reference_type']),
      referenceId: _nullableInt(json['reference_id']),
      description: _requiredString(json['description'], 'description'),
      occurredAt: _requiredDateTime(json['occurred_at'], 'occurred_at'),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      idempotencyKey: _nullableString(json['idempotency_key']),
    );
  }
}

class RewardCatalog {
  const RewardCatalog({
    required this.id,
    required this.rewardCode,
    required this.rewardName,
    required this.description,
    required this.requiredPoints,
    required this.rewardType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.assetFileId,
    this.availableFrom,
    this.availableTo,
  });

  final int id;
  final int? assetFileId;
  final String rewardCode;
  final String rewardName;
  final String description;
  final int requiredPoints;
  final String rewardType;
  final bool isActive;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RewardCatalog.fromJson(Map<String, dynamic> json) {
    return RewardCatalog(
      id: _requiredInt(json['id'], 'id'),
      assetFileId: _nullableInt(json['asset_file']),
      rewardCode: _requiredString(json['reward_code'], 'reward_code'),
      rewardName: _requiredString(json['reward_name'], 'reward_name'),
      description: _requiredString(json['description'], 'description'),
      requiredPoints: _requiredInt(json['required_points'], 'required_points'),
      rewardType: _requiredString(json['reward_type'], 'reward_type'),
      isActive: json['is_active'] == true,
      availableFrom: _nullableDateTime(json['available_from']),
      availableTo: _nullableDateTime(json['available_to']),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
    );
  }
}

class PatientReward {
  const PatientReward({
    required this.id,
    required this.patientAccount,
    required this.rewardCatalogId,
    required this.status,
    required this.earnedAt,
    required this.createdAt,
    this.reward,
    this.pointTransactionId,
    this.pointTransaction,
    this.redeemedAt,
    this.expiresAt,
  });

  final int id;
  final int patientAccount;
  final int rewardCatalogId;
  final RewardCatalog? reward;

  // Backend model field is plural, but the nested API field is singular.
  final int? pointTransactionId;
  final PointTransaction? pointTransaction;

  final String status;
  final DateTime earnedAt;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory PatientReward.fromJson(Map<String, dynamic> json) {
    final rewardJson = json['reward'];
    final transactionJson = json['point_transaction'];

    return PatientReward(
      id: _requiredInt(json['id'], 'id'),
      patientAccount: _requiredInt(json['patient_account'], 'patient_account'),
      rewardCatalogId: _requiredInt(json['reward_catalog'], 'reward_catalog'),
      reward: rewardJson is Map
          ? RewardCatalog.fromJson(Map<String, dynamic>.from(rewardJson))
          : null,
      pointTransactionId: _nullableInt(json['point_transactions']),
      pointTransaction: transactionJson is Map
          ? PointTransaction.fromJson(
              Map<String, dynamic>.from(transactionJson),
            )
          : null,
      status: _requiredString(json['status'], 'status'),
      earnedAt: _requiredDateTime(json['earned_at'], 'earned_at'),
      redeemedAt: _nullableDateTime(json['redeemed_at']),
      expiresAt: _nullableDateTime(json['expires_at']),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
    );
  }
}

class RewardOverview {
  const RewardOverview({required this.available, required this.acquired});

  final List<RewardCatalog> available;
  final List<PatientReward> acquired;

  factory RewardOverview.fromJson(Map<String, dynamic> json) {
    final availableJson = json['available'];
    final acquiredJson = json['acquired'];

    if (availableJson is! List || acquiredJson is! List) {
      throw const FormatException('리워드 목록 응답 형식이 올바르지 않습니다.');
    }

    return RewardOverview(
      available: availableJson
          .whereType<Map>()
          .map(
            (item) => RewardCatalog.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      acquired: acquiredJson
          .whereType<Map>()
          .map(
            (item) => PatientReward.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class RewardRedeemResult {
  const RewardRedeemResult({
    required this.reward,
    required this.pointTransaction,
    required this.alreadyProcessed,
  });

  final PatientReward reward;
  final PointTransaction pointTransaction;
  final bool alreadyProcessed;

  factory RewardRedeemResult.fromJson(Map<String, dynamic> json) {
    final rewardJson = json['reward'];
    final transactionJson = json['point_transaction'];

    if (rewardJson is! Map || transactionJson is! Map) {
      throw const FormatException('리워드 교환 응답 형식이 올바르지 않습니다.');
    }

    return RewardRedeemResult(
      reward: PatientReward.fromJson(Map<String, dynamic>.from(rewardJson)),
      pointTransaction: PointTransaction.fromJson(
        Map<String, dynamic>.from(transactionJson),
      ),
      alreadyProcessed: json['already_processed'] == true,
    );
  }
}

int _requiredInt(Object? value, String fieldName) {
  final result = _nullableInt(value);

  if (result == null) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }

  return result;
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

String _requiredString(Object? value, String fieldName) {
  final result = _nullableString(value);

  if (result == null || result.isEmpty) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }

  return result;
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }

  return value.toString();
}

DateTime _requiredDateTime(Object? value, String fieldName) {
  final result = _nullableDateTime(value);

  if (result == null) {
    throw FormatException('$fieldName 값이 올바르지 않습니다.');
  }

  return result;
}

DateTime? _nullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
