import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HealthActivitySection extends StatelessWidget {
  const HealthActivitySection({
    super.key,
    required this.onWalk,
    required this.onQuiz,
    required this.onBingo,
    required this.onStudio,
  });

  final VoidCallback onWalk;
  final VoidCallback onQuiz;
  final VoidCallback onBingo;
  final VoidCallback onStudio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '\uac74\uac15 \ud65c\ub3d9',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '\uc624\ub298 \ub098\uc5d0\uac8c \ub9de\ub294 \uc791\uc740 \uac74\uac15 \uc2b5\uad00\uc744 \uc2e4\ucc9c\ud574 \ubcf4\uc138\uc694.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 13),
        ),
        const SizedBox(height: 8),
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.40,
          children: [
            _HealthActivityCard(
              title: '\ub9ac\ub4ec\uc0b0\ucc45',
              subtitle:
                  '\uc624\ub298 \uac78\uc74c\uc744 \uac00\ubccd\uac8c \ud655\uc778\ud574\uc694',
              backgroundColor: const Color(0xFFE8F3FF),
              imagePath: 'assets/images/bomi/bomi_walk.png',
              onTap: onWalk,
            ),
            _HealthActivityCard(
              title: '1\ubd84 \uac74\uac15\ud034\uc988',
              subtitle:
                  '1\ubd84\uc73c\ub85c \uac74\uac15 \uc0c1\uc2dd\uc744 \ucc44\uc6cc\uc694',
              backgroundColor: const Color(0xFFFFF3DE),
              imagePath: 'assets/images/bomi/bomi_quiz_thinking.png',
              onTap: onQuiz,
            ),
            _HealthActivityCard(
              title: '\ub450\uadfc\ube59\uace0',
              subtitle:
                  '\uc791\uc740 \uc2e4\ucc9c\uc73c\ub85c \uce78\uc744 \ucc44\uc6cc\uc694',
              backgroundColor: const Color(0xFFFFEAF1),
              imagePath: 'assets/images/bomi/bomi_health_celebrate.png',
              onTap: onBingo,
            ),
            _HealthActivityCard(
              title: '\ubcf4\ubbf8 \uafb8\ubbf8\uae30',
              subtitle:
                  '\ud574\uae08\ud55c \uc544\uc774\ud15c\uc73c\ub85c \uafb8\uba70\uc694',
              backgroundColor: const Color(0xFFEFEEFF),
              imagePath: 'assets/images/bomi/bomi_health_wave.png',
              onTap: onStudio,
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthActivityCard extends StatelessWidget {
  const _HealthActivityCard({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.onTap,
    required this.imagePath,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final VoidCallback onTap;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5EBF3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 9, 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -15,
                top: -17,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0x4DFFFFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0x45FFFFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -3,
                bottom: -7,
                child: SizedBox(
                  width: 84,
                  height: 88,
                  child: Transform.scale(
                    scale: 1.08,
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
