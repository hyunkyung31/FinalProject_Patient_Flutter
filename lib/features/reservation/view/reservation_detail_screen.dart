import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/reservation_preview.dart';

class ReservationDetailScreen extends StatelessWidget {
  const ReservationDetailScreen({super.key, required this.reservation});
  final ReservationPreview reservation;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('예약 상세')),
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const _PreviewNotice(),
              const SizedBox(height: 24),
              Text(
                reservation.status,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${reservation.dateLabel} · ${reservation.timeLabel}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: '병원', value: reservation.hospital),
                    const Divider(height: 28),
                    _DetailRow(label: '진료과', value: reservation.department),
                    const Divider(height: 28),
                    _DetailRow(label: '의료진', value: reservation.doctor),
                    const Divider(height: 28),
                    _DetailRow(label: '예약 상태', value: reservation.status),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '예약 안내',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                '실제 예약의 방문 장소와 준비사항은 병원에서 제공하는 안내를 확인해 주세요.',
                style: TextStyle(height: 1.6, color: AppColors.mutedText),
              ),
              if (!reservation.completed) ...[
                const SizedBox(height: 24),
                const OutlinedButton(onPressed: null, child: Text('예약 변경')),
                const SizedBox(height: 8),
                const OutlinedButton(onPressed: null, child: Text('예약 취소')),
                const SizedBox(height: 12),
                const Text(
                  '예시 화면에서는 예약을 변경하거나 취소할 수 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: AppColors.mutedText),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 80,
        child: Text(label, style: const TextStyle(color: AppColors.mutedText)),
      ),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.lightBlue,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      '디자인 확인용 예시 예약입니다.\n실제 접수된 예약이 아닙니다.',
      style: TextStyle(color: AppColors.navy, height: 1.5),
    ),
  );
}
