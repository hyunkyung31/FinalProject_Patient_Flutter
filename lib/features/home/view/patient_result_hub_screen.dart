import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../ai_result/repository/patient_ai_result_repository.dart';
import '../../ai_result/view/patient_ai_result_list_screen.dart';
import '../../lab_result/repository/lab_result_repository.dart';
import '../../lab_result/view/lab_result_list_screen.dart';
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

          // 혈액검사 결과
          _ResultMenuCard(
            icon: Icons.science_outlined,
            title: '혈액검사',
            subtitle: '혈액검사 항목과 결과를 확인해요.',
            onTap: () => _open(
              context,
              LabResultListScreen(
                repository: PatientLabResultRepository(repository.client),
              ),
            ),
          ),

          // 2D 관상동맥조영술(XCA) 결과
          _ResultMenuCard(
            icon: Icons.monitor_heart_outlined,
            title: '혈관조영술',
            subtitle: '공개된 관상동맥조영술 분석 결과를 확인해요.',
            onTap: () => _open(
              context,
              PatientAIResultListScreen(
                repository: PatientAIResultRepository(repository.client),
                analysisType: 'ANGIO_2D',
                title: '혈관조영술',
                emptyTitle: '공개된 혈관조영술 결과가 없어요.',
                emptyMessage: '검사 이력이 없거나 아직 의료진 검토·공개 전일 수 있어요.',
              ),
            ),
          ),

          // 관상동맥 CT(CCTA) 결과
          _ResultMenuCard(
            icon: Icons.view_in_ar_rounded,
            title: '혈관 CT',
            subtitle: '공개된 혈관 CT 분석 결과를 확인해요.',
            onTap: () => _open(
              context,
              PatientAIResultListScreen(
                repository: PatientAIResultRepository(repository.client),
                analysisType: 'CCTA',
                title: '혈관 CT',
                emptyTitle: '공개된 혈관 CT 결과가 없어요.',
                emptyMessage: '검사 이력이 없거나 아직 공개 전일 수 있어요.',
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
