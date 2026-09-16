import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../ai_result/repository/patient_ai_result_repository.dart';
import '../../ai_result/view/patient_ai_result_list_screen.dart';
import '../../lab_result/repository/lab_result_repository.dart';
import '../../lab_result/view/lab_result_list_screen.dart';
import '../../patient_report/repository/patient_report_repository.dart';
import '../../patient_report/view/patient_report_list_screen.dart';
import '../../reservation/repository/reservation_repository.dart';

class PatientResultHubScreen extends StatelessWidget {
  const PatientResultHubScreen({super.key, required this.repository});

  final ReservationRepository repository;

  // 선택한 결과 화면으로 이동
  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검사결과')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '검사와 분석 결과를 확인하세요.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '의료진이 확인하고 공개한 결과를 중심으로 제공합니다.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 24),

          // 검사 결과
          _ResultMenuCard(
            icon: Icons.science_outlined,
            title: '검사 결과',
            subtitle: '혈액검사 및 검사 결과 확인',
            onTap: () => _open(
              context,
              LabResultListScreen(
                repository: PatientLabResultRepository(repository.client),
              ),
            ),
          ),

          // AI 분석 결과
          _ResultMenuCard(
            icon: Icons.insights_outlined,
            title: 'AI 분석 결과',
            subtitle: '공개된 AI 분석 결과와 설명 확인',
            onTap: () => _open(
              context,
              PatientAIResultListScreen(
                repository: PatientAIResultRepository(repository.client),
              ),
            ),
          ),

          // 환자용 PDF 리포트
          _ResultMenuCard(
            icon: Icons.picture_as_pdf_outlined,
            title: '환자 리포트',
            subtitle: '최종 결과와 PDF 리포트 확인',
            onTap: () => _open(
              context,
              PatientReportListScreen(
                repository: PatientReportRepository(repository.client),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMenuCard extends StatelessWidget {
  const _ResultMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, size: 30, color: AppColors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
