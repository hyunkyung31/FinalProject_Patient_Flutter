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
        const SizedBox(height: 13),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.46,
          children: [
            _HealthActivityCard(
              title: '\ub9ac\ub4ec\uc0b0\ucc45',
              subtitle:
                  '\uc624\ub298\uc758 \uac78\uc74c\uc744 \ud655\uc778\ud574\uc694',
              backgroundColor: const Color(0xFFEDF5FF),
              imagePath: 'assets/images/bomi/bomi_walk.png',
              onTap: onWalk,
            ),
            _HealthActivityCard(
              title: '1\ubd84 \uac74\uac15\ud034\uc988',
              subtitle:
                  '\ud558\ub8e8 \ud55c \uac00\uc9c0 \uac74\uac15 \uc0c1\uc2dd',
              backgroundColor: const Color(0xFFFFF3F7),
              icon: Icons.lightbulb_rounded,
              iconColor: const Color(0xFFFFB02E),
              onTap: onQuiz,
            ),
            _HealthActivityCard(
              title: '\ub450\uadfc\ube59\uace0',
              subtitle:
                  '\uc791\uc740 \uc2e4\ucc9c\uc73c\ub85c \uce78\uc744 \ucc44\uc6cc\uc694',
              backgroundColor: const Color(0xFFFFF3F7),
              icon: Icons.grid_view_rounded,
              iconColor: const Color(0xFFF75283),
              onTap: onBingo,
            ),
            _HealthActivityCard(
              title: '\ubcf4\ubbf8 \uc2a4\ud29c\ub514\uc624',
              subtitle:
                  '\ubcf4\uc0c1\uc73c\ub85c \ubc1b\uc740 \uc544\uc774\ud15c\uc744 \uafb8\uba70\uc694',
              backgroundColor: const Color(0xFFEDF5FF),
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFF4E7DE9),
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
    this.imagePath,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final VoidCallback onTap;
  final String? imagePath;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 11),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomRight,
                child: imagePath != null
                    ? SizedBox(
                        width: 76,
                        height: 82,
                        child: Image.asset(imagePath!, fit: BoxFit.contain),
                      )
                    : Icon(icon, color: iconColor, size: 44),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 108,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          height: 1.3,
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
