import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../model/reward.dart';
import '../repository/reward_repository.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({
    super.key,
    required this.repository,
  });

  final RewardRepository repository;

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final Uuid _uuid = const Uuid();

  PointAccount? _account;
  RewardOverview? _overview;
  List<PointTransaction> _transactions = const [];

  bool _loading = true;
  String? _error;

  final Set<int> _redeemingRewardIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final account = await widget.repository.getPointAccount();
      final overview = await widget.repository.getRewards();
      final transactions = await widget.repository.getPointTransactions();

      transactions.sort(
        (a, b) => b.occurredAt.compareTo(a.occurredAt),
      );

      if (!mounted) return;

      setState(() {
        _account = account;
        _overview = overview;
        _transactions = transactions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = rewardErrorMessage(error);
      });
    }
  }

  Future<void> _redeem(RewardCatalog reward) async {
    final account = _account;

    if (account == null) return;

    if (account.balance < reward.requiredPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('보유 포인트가 부족해요.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('리워드 교환'),
          content: Text(
            '${reward.rewardName}\n\n'
            '${_points(reward.requiredPoints)}P를 사용해 교환할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('교환하기'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _redeemingRewardIds.add(reward.id);
    });

    try {
      final result = await widget.repository.redeemReward(
        rewardId: reward.id,
        idempotencyKey: _uuid.v4(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyProcessed
                ? '이미 처리된 교환 요청이에요.'
                : '${reward.rewardName} 교환이 완료됐어요.',
          ),
        ),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rewardErrorMessage(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _redeemingRewardIds.remove(reward.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          '리워드',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            if (_loading)
              const _LoadingState()
            else if (_error != null)
              _ErrorState(
                message: _error!,
                onRetry: _load,
              )
            else ...[
              if (_account != null)
                _PointSummaryCard(account: _account!),
              const SizedBox(height: 26),
              _sectionTitle(
                title: '교환 가능한 리워드',
                description: '건강 활동으로 모은 포인트를 사용할 수 있어요.',
              ),
              const SizedBox(height: 14),
              if ((_overview?.available ?? const []).isEmpty)
                const _EmptyCard(
                  message: '현재 교환 가능한 리워드가 없어요.',
                )
              else
                ..._overview!.available.map(
                  (reward) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RewardCard(
                      reward: reward,
                      balance: _account?.balance ?? 0,
                      redeeming:
                          _redeemingRewardIds.contains(reward.id),
                      onRedeem: () => _redeem(reward),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              _sectionTitle(
                title: '내 리워드',
                description: '지금까지 획득한 리워드예요.',
              ),
              const SizedBox(height: 14),
              if ((_overview?.acquired ?? const []).isEmpty)
                const _EmptyCard(
                  message: '아직 획득한 리워드가 없어요.',
                )
              else
                ..._overview!.acquired.map(
                  (reward) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AcquiredRewardCard(reward: reward),
                  ),
                ),
              const SizedBox(height: 22),
              _sectionTitle(
                title: '최근 포인트 내역',
                description: '최근 적립·사용 내역을 확인할 수 있어요.',
              ),
              const SizedBox(height: 14),
              if (_transactions.isEmpty)
                const _EmptyCard(
                  message: '아직 포인트 내역이 없어요.',
                )
              else
                _TransactionCard(
                  transactions: _transactions.take(5).toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _PointSummaryCard extends StatelessWidget {
  const _PointSummaryCard({
    required this.account,
  });

  final PointAccount account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '나의 두근 포인트',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_points(account.balance)} P',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PointStat(
                  label: '누적 적립',
                  value: '${_points(account.totalEarned)}P',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PointStat(
                  label: '누적 사용',
                  value: '${_points(account.totalSpent)}P',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointStat extends StatelessWidget {
  const _PointStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.balance,
    required this.redeeming,
    required this.onRedeem,
  });

  final RewardCatalog reward;
  final int balance;
  final bool redeeming;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final enoughPoints = balance >= reward.requiredPoints;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7EBF1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6FC),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.rewardName,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (reward.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        reward.description,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_points(reward.requiredPoints)} P',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed:
                      enoughPoints && !redeeming ? onRedeem : null,
                  child: redeeming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          enoughPoints ? '교환하기' : '포인트 부족',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcquiredRewardCard extends StatelessWidget {
  const _AcquiredRewardCard({
    required this.reward,
  });

  final PatientReward reward;

  @override
  Widget build(BuildContext context) {
    final catalog = reward.reward;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7EBF1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF4E9A71),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catalog?.rewardName ?? '리워드 #${reward.rewardCatalogId}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_date(reward.earnedAt)} · ${reward.status}',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transactions,
  });

  final List<PointTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7EBF1),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < transactions.length; index++) ...[
            _TransactionRow(
              transaction: transactions[index],
            ),
            if (index != transactions.length - 1)
              const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
  });

  final PointTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final earned = transaction.isEarned;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: earned
                  ? const Color(0xFFEAF7EF)
                  : const Color(0xFFFFF0EE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              earned
                  ? Icons.add_rounded
                  : Icons.remove_rounded,
              color: earned
                  ? const Color(0xFF3D8A61)
                  : const Color(0xFFC9655A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _date(transaction.occurredAtKst),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${earned ? '+' : '-'}${_points(transaction.amount.abs())}P',
            style: TextStyle(
              color: earned
                  ? const Color(0xFF3D8A61)
                  : const Color(0xFFC9655A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 120),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7EBF1),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 13,
        ),
      ),
    );
  }
}

String _points(int value) {
  final negative = value < 0;
  final text = value.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < text.length; index++) {
    if (index > 0 && (text.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[index]);
  }

  return '${negative ? '-' : ''}$buffer';
}

String _date(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');

  return '${local.year}.$month.$day';
}
