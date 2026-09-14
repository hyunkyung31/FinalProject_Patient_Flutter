import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/medical_timeline.dart';

class MedicalHistoryDetailScreen extends StatelessWidget {
  const MedicalHistoryDetailScreen({super.key, required this.item});

  final MedicalTimelineItem item;

  @override
  Widget build(BuildContext context) {
    final presentation = _eventPresentation(item.eventType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('진료 · 검사이력 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(presentation.icon, color: AppColors.navy),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title.isEmpty ? presentation.label : item.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.schedule_rounded,
                label: '일시',
                value: _dateTimeText(item.occurredAtKst),
              ),
              if (item.status.isNotEmpty) ...[
                const Divider(height: 28),
                _InfoRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: '상태',
                  value: _statusLabel(item.status),
                ),
              ],
            ],
          ),
          if (item.summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: '내용',
              child: Text(
                item.summary,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.65,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
          if (item.data.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: '상세 정보',
              child: Text(
                item.data,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.blue),
        const SizedBox(width: 12),
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            child,
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
