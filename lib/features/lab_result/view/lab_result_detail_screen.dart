import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/lab_result.dart';

class LabResultDetailScreen extends StatelessWidget {
  const LabResultDetailScreen({super.key, required this.result});

  final LabResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('혈액검사 결과')),
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
                  child: const Icon(
                    Icons.science_outlined,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    result.displayTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _InfoRow(
                    label: '검사일',
                    value: _dateTimeText(result.collectedAt),
                  ),
                  const Divider(height: 28),
                  _InfoRow(label: '상태', value: _statusLabel(result.status)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '결과 요약',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.summaryText.trim().isEmpty
                        ? '등록된 결과 요약이 없습니다.'
                        : result.summaryText,
                    style: const TextStyle(height: 1.6, color: AppColors.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String _statusLabel(String status) {
  return switch (status.toUpperCase()) {
    'FINAL' => '최종 확인',
    'CORRECTED' => '수정됨',
    'DRAFT' => '작성 중',
    _ => status,
  };
}

String _dateTimeText(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));

  String two(int value) => value.toString().padLeft(2, '0');

  return '${kst.year}.${two(kst.month)}.${two(kst.day)} '
      '${two(kst.hour)}:${two(kst.minute)}';
}
