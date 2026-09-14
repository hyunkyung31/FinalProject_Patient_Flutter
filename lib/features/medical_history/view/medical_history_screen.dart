import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/medical_timeline.dart';
import '../repository/medical_history_repository.dart';
import 'medical_history_detail_screen.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key, required this.repository});

  final MedicalHistoryRepository repository;

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late Future<MedicalTimeline> _timeline;

  @override
  void initState() {
    super.initState();
    _timeline = widget.repository.getTimeline();
  }

  Future<void> _reload() async {
    final future = widget.repository.getTimeline();

    setState(() {
      _timeline = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder에서 오류 상태를 표시합니다.
    }
  }

  void _openDetail(MedicalTimelineItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => MedicalHistoryDetailScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('진료 · 검사이력'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<MedicalTimeline>(
        future: _timeline,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: medicalHistoryErrorMessage(snapshot.error!),
              onRetry: _reload,
            );
          }

          final timeline = snapshot.data;

          if (timeline == null || timeline.results.isEmpty) {
            return _EmptyView(onRefresh: _reload);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: timeline.results.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: 12)
                  : const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _Header();
                }

                final item = timeline.results[index - 1];

                return _TimelineCard(
                  item: item,
                  onTap: () => _openDetail(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_rounded, color: AppColors.navy),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '병원기록에 연결된 진료와 검사 내역을 최신 순으로 확인할 수 있어요.',
              style: TextStyle(
                color: AppColors.navy,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.item, required this.onTap});

  final MedicalTimelineItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = _eventPresentation(item.eventType);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(kind.icon, color: AppColors.navy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.title.isEmpty ? kind.label : item.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.status.isNotEmpty) ...[
                    _StatusChip(status: item.status),
                    const SizedBox(width: 6),
                  ],
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _dateTimeText(item.occurredAtKst),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
              if (item.summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.55, color: AppColors.text),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.history_rounded, size: 58, color: AppColors.mutedText),
          SizedBox(height: 20),
          Text(
            '진료·검사이력이 없어요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text(
            '진료 또는 검사가 완료되면 이곳에서 확인할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

({String label, IconData icon}) _eventPresentation(String eventType) {
  return switch (eventType.toUpperCase()) {
    'ENCOUNTER' => (label: '진료', icon: Icons.medical_information_outlined),
    'EXAMINATION' ||
    'EXAM' => (label: '검사', icon: Icons.monitor_heart_outlined),
    'EXAMINATION_RESULT' ||
    'RESULT' => (label: '검사 결과', icon: Icons.fact_check_outlined),
    _ => (label: eventType.replaceAll('_', ' '), icon: Icons.history_rounded),
  };
}

String _statusLabel(String status) {
  return switch (status.toUpperCase()) {
    'COMPLETED' => '완료',
    'IN_PROGRESS' => '진행 중',
    'SCHEDULED' => '예정',
    'OPEN' => '진행 중',
    'CANCELED' || 'CANCELLED' => '취소',
    'FAILED' => '실패',
    _ => status,
  };
}

String _dateTimeText(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');

  return '${date.year}.${two(date.month)}.${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}
