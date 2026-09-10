import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 예약 API 연결 전의 시작 화면. 실제 일정과 신청은 서버 연동 후 활성화합니다.
class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('진료 예약')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              const Text(
                '진료 예약을 시작해 볼까요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '진료과와 의료진을 선택하고\n예약 가능한 날짜와 시간을 확인해 주세요.',
                style: TextStyle(height: 1.6, color: AppColors.mutedText),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.navy),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '온라인 예약을 준비 중이에요.\n'
                        '진료과와 예약 일정이 제공되면 이 화면에서 신청할 수 있어요. '
                        '병원기록이 없는 분의 예약 절차도 함께 안내할게요.',
                        style: TextStyle(height: 1.6, color: AppColors.navy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _ReservationStep(
                number: '1',
                title: '진료과 선택',
                icon: Icons.local_hospital_outlined,
                message: '진료과 목록을 준비하고 있어요.',
                active: true,
              ),
              const SizedBox(height: 16),
              const _ReservationStep(
                number: '2',
                title: '의료진 선택',
                icon: Icons.person_outline,
                message: '진료과를 선택하면 의료진을 확인할 수 있어요.',
              ),
              const SizedBox(height: 16),
              const _ReservationStep(
                number: '3',
                title: '날짜·시간 선택',
                icon: Icons.calendar_month_outlined,
                message: '의료진을 선택하면 예약 가능한 일정을 확인할 수 있어요.',
              ),
              const SizedBox(height: 24),
              const Text(
                '진료과 · 의료진 · 날짜와 시간을 선택한 뒤 신청해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText, height: 1.5),
              ),
              const SizedBox(height: 12),
              const FilledButton(
                onPressed: null,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('예약 신청'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReservationStep extends StatelessWidget {
  const _ReservationStep({
    required this.number,
    required this.title,
    required this.icon,
    required this.message,
    this.active = false,
  });

  final String number;
  final String title;
  final IconData icon;
  final String message;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: active ? AppColors.blue : const Color(0xFFE2E8F0),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: active ? AppColors.navy : AppColors.lightBlue,
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 14,
                  color: active ? Colors.white : AppColors.navy,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            Icon(icon, color: AppColors.mutedText),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          message,
          style: const TextStyle(height: 1.5, color: AppColors.mutedText),
        ),
      ],
    ),
  );
}
