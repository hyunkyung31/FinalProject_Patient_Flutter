import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/reservation_preview.dart';
import '../view/reservation_detail_screen.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation});
  final ReservationPreview reservation;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                reservation.status,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                '예시 데이터',
                style: TextStyle(color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${reservation.dateLabel} · ${reservation.timeLabel}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '${reservation.hospital} · ${reservation.department}',
            style: const TextStyle(height: 1.5),
          ),
          Text(
            reservation.doctor,
            style: const TextStyle(color: AppColors.mutedText, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      ReservationDetailScreen(reservation: reservation),
                ),
              ),
              child: const Text('예약 상세 보기'),
            ),
          ),
        ],
      ),
    ),
  );
}
