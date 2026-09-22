import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../ai_result/repository/patient_ai_result_repository.dart';
import '../../ai_result/view/patient_ai_result_list_screen.dart';
import '../../lab_result/repository/lab_result_repository.dart';
import '../../lab_result/view/lab_result_list_screen.dart';
import '../../reservation/repository/reservation_repository.dart';

class PatientResultHubScreen extends StatelessWidget {
  const PatientResultHubScreen({
    super.key,
    required this.repository,
    this.embedded = false,
  });

  final ReservationRepository repository;
  final bool embedded;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? colors.primary : AppColors.blue;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: embedded
          ? null
          : AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
            ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, embedded ? 18 : 8, 20, 28),
        children: [
          _ResultHero(accent: accent, dark: dark),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 4,
                height: 19,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '검사 종류',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _ResultMenuCard(
            icon: Icons.science_outlined,
            title: '혈액검사',
            subtitle: '혈액검사 항목과 수치, 정상 범위를 확인해요.',
            onTap: () => _open(
              context,
              LabResultListScreen(
                repository: PatientLabResultRepository(repository.client),
              ),
            ),
          ),

          _ResultMenuCard(
            icon: Icons.favorite_outline_rounded,
            title: '심혈관 위험도',
            subtitle: '임상정보와 혈액검사 등을 바탕으로 분석한 심혈관 위험도를 확인해요.',
            onTap: () => _open(
              context,
              PatientAIResultListScreen(
                repository: PatientAIResultRepository(repository.client),
                analysisType: 'CLINICAL',
                title: '심혈관 위험도',
                emptyTitle: '공개된 심혈관 위험도 결과가 없어요.',
                emptyMessage:
                    '의료진 검토 후 공개된 결과가 있으면 이곳에서 확인할 수 있어요.',
              ),
            ),
          ),

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
                emptyMessage: '검사 이력이 없거나 아직 의료진 검토·공개 전일 수 있어요.',
              ),
            ),
          ),

          const SizedBox(height: 2),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '의료진이 확인하고 공개한 결과만 표시됩니다.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.45,
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

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.accent, required this.dark});

  final Color accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final titleColor = dark ? colors.primary : const Color(0xFF426FCF);

    final descriptionColor = dark
        ? colors.onSurfaceVariant
        : const Color(0xFF74839D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      decoration: BoxDecoration(
        gradient: dark
            ? LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.16),
                  colors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFEAF4FF), Color(0xFFF8FBFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? colors.outlineVariant.withValues(alpha: 0.55)
              : const Color(0xFFD7E6FB),
        ),
        boxShadow: dark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0xFFB8D4FA).withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: dark
                  ? colors.onSurface.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dark
                    ? colors.outlineVariant.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.92),
              ),
            ),
            child: Icon(Icons.assignment_outlined, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '검사결과',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '나의 검사 종류별 기록과 결과를 확인하세요.',
                  style: TextStyle(
                    color: descriptionColor,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? colors.primary : AppColors.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: dark
                  ? colors.outlineVariant.withValues(alpha: 0.6)
                  : AppColors.navy.withValues(alpha: 0.10),
            ),
            boxShadow: dark
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(19),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? 0.18 : 0.11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, size: 25, color: accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 17,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
