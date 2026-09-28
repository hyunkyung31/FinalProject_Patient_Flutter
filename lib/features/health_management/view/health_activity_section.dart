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
              title: '\ub450\uadfc\uc0b0\ucc45',
              subtitle:
                  '\uc624\ub298 \uac78\uc74c\uc744 \uac00\ubccd\uac8c \ud655\uc778\ud574\uc694',
              backgroundColor: const Color(0xFFE8F3FF),
              theme: _HealthActivityTheme.walk,
              imagePath: 'assets/images/bomi/bomi_walk.png',
              onTap: onWalk,
            ),
            _HealthActivityCard(
              title: '1\ubd84 \uac74\uac15\ud034\uc988',
              subtitle:
                  '1\ubd84\uc73c\ub85c \uac74\uac15 \uc0c1\uc2dd\uc744 \ucc44\uc6cc\uc694',
              backgroundColor: const Color(0xFFFFF3DE),
              theme: _HealthActivityTheme.quiz,
              imagePath: 'assets/images/bomi/bomi_quiz_thinking.png',
              onTap: onQuiz,
            ),
            _HealthActivityCard(
              title: '\ub450\uadfc\ube59\uace0',
              subtitle:
                  '\uc791\uc740 \uc2e4\ucc9c\uc73c\ub85c \uce78\uc744 \ucc44\uc6cc\uc694',
              backgroundColor: const Color(0xFFFFEAF1),
              theme: _HealthActivityTheme.bingo,
              imagePath: 'assets/images/bomi/bomi_health_celebrate.png',
              onTap: onBingo,
            ),
            _HealthActivityCard(
              title: '\ub098\ub9cc\uc758 \ubcf4\ubbf8',
              subtitle:
                  '\ud574\uae08\ud55c \uc544\uc774\ud15c\uc73c\ub85c \uafb8\uba70\uc694',
              backgroundColor: const Color(0xFFEFEEFF),
              theme: _HealthActivityTheme.studio,
              imagePath: 'assets/images/bomi/bomi_health_wave.png',
              onTap: onStudio,
            ),
          ],
        ),
      ],
    );
  }
}

enum _HealthActivityTheme { walk, quiz, bingo, studio }

class _HealthActivityCard extends StatelessWidget {
  const _HealthActivityCard({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.theme,
    required this.onTap,
    required this.imagePath,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final _HealthActivityTheme theme;
  final VoidCallback onTap;
  final String imagePath;

  List<Widget> _themeDecorations() {
    return switch (theme) {
      // 두근산책
      _HealthActivityTheme.walk => const [
        Positioned(
          right: 66,
          bottom: 1,
          child: Icon(Icons.park_rounded, size: 29, color: Color(0x5549A875)),
        ),
        Positioned(
          right: 94,
          bottom: 3,
          child: Icon(
            Icons.local_florist_rounded,
            size: 16,
            color: Color(0x77EE829E),
          ),
        ),
        Positioned(
          right: 55,
          top: 3,
          child: Icon(
            Icons.local_florist_rounded,
            size: 12,
            color: Color(0x6656B986),
          ),
        ),
      ],

      // 1분 건강퀴즈
      _HealthActivityTheme.quiz => const [
        Positioned(
          right: 66,
          top: 2,
          child: Icon(
            Icons.lightbulb_rounded,
            size: 25,
            color: Color(0x77E3A329),
          ),
        ),
        Positioned(
          right: 94,
          bottom: 3,
          child: Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0x669DAE55),
          ),
        ),
        Positioned(
          right: 55,
          bottom: 5,
          child: Icon(Icons.quiz_rounded, size: 15, color: Color(0x55D79E32)),
        ),
      ],

      // 두근빙고
      _HealthActivityTheme.bingo => const [
        Positioned(
          right: 66,
          top: 3,
          child: Icon(
            Icons.grid_view_rounded,
            size: 23,
            color: Color(0x66DF668C),
          ),
        ),
        Positioned(
          right: 94,
          bottom: 2,
          child: Icon(Icons.star_rounded, size: 18, color: Color(0x77EFA142)),
        ),
        Positioned(
          right: 55,
          bottom: 5,
          child: Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Color(0x66DF678F),
          ),
        ),
      ],

      // 나만의 보미
      _HealthActivityTheme.studio => const [
        Positioned(
          right: 66,
          top: 2,
          child: Icon(
            Icons.palette_rounded,
            size: 24,
            color: Color(0x66736BDB),
          ),
        ),
        Positioned(
          right: 94,
          bottom: 3,
          child: Icon(
            Icons.favorite_rounded,
            size: 15,
            color: Color(0x77E48DB4),
          ),
        ),
        Positioned(
          right: 55,
          bottom: 5,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 15,
            color: Color(0x778078E5),
          ),
        ),
      ],
    };
  }

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
              ..._themeDecorations(),
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
