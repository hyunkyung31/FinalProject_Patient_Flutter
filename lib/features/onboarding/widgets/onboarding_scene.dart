import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../model/onboarding_page.dart';
import 'bomi_waving_character.dart';

/// Each scene is composed of real text, cards, drawings and one character PNG.
class OnboardingScene extends StatefulWidget {
  const OnboardingScene({super.key, required this.index, required this.active});
  final int index;
  final bool active;

  @override
  State<OnboardingScene> createState() => _OnboardingSceneState();
}

class _OnboardingSceneState extends State<OnboardingScene>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant OnboardingScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncMotion();
  }

  void _syncMotion() {
    _entrance.stop();
    if (_reduceMotion) {
      _entrance.value = 1;
    } else if (widget.active) {
      _entrance.forward(from: 0);
    } else {
      _entrance.value = 0;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  double _phase(double start, [double end = 1]) => Curves.easeOutCubic
      .transform(((_entrance.value - start) / (end - start)).clamp(0.0, 1.0));

  Widget _reveal(Widget child, double start) {
    final progress = _phase(start, math.min(1, start + 0.38));
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 24 * (1 - progress)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = OnboardingPage.pages[widget.index];
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        final progress = _phase(0.25);
        final cards = _cards(progress);
        return SingleChildScrollView(
          key: PageStorageKey('scene-scroll-${widget.index}'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _reveal(
                Column(
                  children: [
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.3,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                0,
              ),
              const SizedBox(height: 10),
              _hero(),
              for (var i = 0; i < cards.length; i++) ...[
                const SizedBox(height: 12),
                _reveal(cards[i], 0.12 + i * 0.14),
              ],
              const SizedBox(height: 16),
              const Text(
                '사용 방법을 보여주는 예시 화면입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hero() {
    const characters = [
      'bomi_13_greeting',
      'bomi_02_smile',
      'bomi_18_chart',
      'bomi_17_ai_check',
      'bomi_18_chart',
      'bomi_12_celebration',
      'bomi_13_greeting',
    ];
    final t = ((_entrance.value - 0.04) / 0.65).clamp(0.0, 1.0);
    final enter = Curves.easeOutCubic.transform(t);
    final settle = math.sin(t * math.pi) * (1 - t);
    final greeting = math.sin(t * math.pi * 3) * (1 - t);
    // Finish appearing first; only the separately clipped arm waves.
    final greetingEntry = _phase(0.02, 0.24);
    final waveTime = ((_entrance.value - 0.25) / 0.70).clamp(0.0, 1.0);
    final greetingWave = waveTime <= 0 || waveTime >= 1 || _reduceMotion
        ? 0.0
        : math.sin(waveTime * math.pi * 5) *
              math.sin(waveTime * math.pi) *
              0.24;
    final (dx, dy, angle, scale) = switch (widget.index) {
      0 => (0.0, 12 * (1 - greetingEntry), 0.0, 0.94 + 0.06 * greetingEntry),
      1 => (0.0, 12 * (1 - enter), 0.0, 0.72 + 0.28 * enter + settle * 0.14),
      2 => (-54 * (1 - enter), 0.0, -0.14 * (1 - enter) + settle * 0.08, 1.0),
      3 => (
        44 * (1 - enter),
        0.0,
        0.15 * (1 - enter) - settle * 0.10,
        0.92 + 0.08 * enter,
      ),
      4 => (0.0, 28 * (1 - enter), -settle * 0.07, 0.88 + 0.12 * enter),
      5 => (
        0.0,
        -math.sin(t * math.pi * 2).abs() * 22 * (1 - t),
        greeting * 0.10,
        0.85 + 0.15 * enter,
      ),
      _ => (
        60 * (1 - enter),
        0.0,
        0.18 * (1 - enter) - settle * 0.12,
        0.9 + 0.1 * enter,
      ),
    };
    final accent = _phase(0.40, 0.78);
    return SizedBox(
      height: 166,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 0.86 + 0.14 * enter,
            child: Container(
              width: 190,
              height: 135,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80),
                gradient: const LinearGradient(
                  colors: [AppColors.lightBlue, AppColors.softPink],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            child: Opacity(
              opacity: enter * 0.12,
              child: Container(
                width: 78,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          if (widget.index > 0 &&
              widget.index != 5 &&
              widget.index != 6 &&
              !_reduceMotion &&
              _entrance.value < 0.90)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: ValueKey('arrival-effect-${widget.index}'),
                  painter: _ArrivalEffectPainter(
                    widget.index,
                    ((_entrance.value - 0.20) / 0.7).clamp(0.0, 1.0),
                    _reduceMotion,
                  ),
                ),
              ),
            ),
          if (widget.index == 5)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CelebrationPainter(_phase(0.55), _reduceMotion),
                ),
              ),
            ),
          Opacity(
            opacity: _phase(0.04, 0.20),
            child: Transform.translate(
              key: ValueKey('bomi-motion-${widget.index}'),
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: angle,
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 148,
                    height: 160,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: ClipRect(
                        child: Align(
                          widthFactor: 0.40,
                          heightFactor: 0.44,
                          child: widget.index == 0
                              ? BomiWavingCharacter(armAngle: greetingWave)
                              : Image.asset(
                                  'assets/images/bomi/${characters[widget.index]}.png',
                                  width: 1024,
                                  height: 1024,
                                  excludeFromSemantics: true,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.index == 6)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 140, top: 15),
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: accent,
                    child: Transform.translate(
                      key: const ValueKey('chatbot-bubble-motion'),
                      offset: Offset(0, 10 * (1 - accent)),
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * accent,
                        alignment: Alignment.bottomLeft,
                        child: CustomPaint(
                          key: const ValueKey('chatbot-speech-bubble'),
                          size: const Size(62, 52),
                          painter: _SpeechBubblePainter(
                            ((_entrance.value - 0.55) / 0.45).clamp(0.0, 1.0),
                            _reduceMotion,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _cards(double progress) => switch (widget.index) {
    0 => [
      _card(
        '다가오는 진료',
        Icons.calendar_month_rounded,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '10월 20일 · 오전 10:30',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('순환기내과 · 예약 승인 완료'),
          ],
        ),
      ),
      _card(
        '내 건강정보',
        Icons.favorite_outline,
        const Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [Text('진료 일정'), Text('검사결과'), Text('처방 조회')],
        ),
      ),
    ],
    1 => [
      _card(
        '소셜 로그인',
        Icons.lock_outline_rounded,
        Column(
          children: [
            _serviceRow(
              '카카오로 시작하기',
              Icons.chat_bubble_outline,
              const Color(0xFFFEE500),
            ),
            const SizedBox(height: 8),
            _serviceRow(
              'Google로 시작하기',
              Icons.account_circle_outlined,
              AppColors.lightBlue,
            ),
          ],
        ),
      ),
      _card(
        '본인인증과 병원 연결',
        Icons.fingerprint_rounded,
        const Text(
          '내 계정과 병원기록을 연결해요.\n생체인증으로 기기에서 간편하게 잠금을 해제해요.',
          style: TextStyle(height: 1.6),
        ),
      ),
    ],
    2 => [
      _card(
        '예약 날짜 선택',
        Icons.calendar_month_rounded,
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('10월 · 예시 일정'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    width: 42,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == (progress * 2).floor()
                          ? AppColors.navy
                          : AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${10 + i}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: i == (progress * 2).floor()
                            ? Colors.white
                            : AppColors.navy,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      _card(
        '선택한 일정 확인',
        Icons.schedule_rounded,
        Text(
          '10월 ${10 + (progress * 2).floor()}일 · 오전 10:30\n신청 후 승인 상태를 확인하세요.',
          style: const TextStyle(height: 1.6),
        ),
      ),
    ],
    3 => [
      _card(
        '혈액검사 변화',
        Icons.show_chart_rounded,
        Column(
          children: [
            SizedBox(
              height: 68,
              width: double.infinity,
              child: CustomPaint(painter: _TrendPainter(progress)),
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('이전 검사')),
                Expanded(child: Text('최근 검사', textAlign: TextAlign.right)),
              ],
            ),
          ],
        ),
      ),
      _card(
        'AI 분석 수치 · 예시',
        Icons.analytics_outlined,
        Wrap(
          spacing: 32,
          runSpacing: 12,
          children: [
            _metric('CAD 위험도', '${(27 * progress).round()}%'),
            _metric('CAC Score', '${(128 * progress).round()}'),
          ],
        ),
      ),
    ],
    4 => [
      _card(
        'AI 분석 결과',
        Icons.auto_awesome_outlined,
        const Text('의료진이 공개한 분석 결과와 설명을 확인해요.'),
      ),
      _card(
        '의료진 소견',
        Icons.medical_services_outlined,
        const Text('담당 의료진의 판단과 권고사항을 함께 읽어요.'),
      ),
      _card(
        '최종 보고서',
        Icons.picture_as_pdf_outlined,
        const Text('공개된 보고서를 PDF로 확인해요.'),
      ),
    ],
    5 => [
      _card(
        '오늘의 건강 미션',
        Icons.favorite_outline,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('오늘의 미션 진행률')),
                Text(
                  '${(75 * progress).round()}%',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: .75 * progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: AppColors.lightBlue,
              semanticsLabel: '건강 미션 예시',
              semanticsValue: '${(75 * progress).round()}%',
            ),
          ],
        ),
      ),
      _card(
        '차곡차곡 쌓이는 리워드',
        Icons.stars_rounded,
        _metric('예시 적립 포인트', '+${(100 * progress).round()} P'),
      ),
    ],
    _ => [
      _card(
        '보미에게 물어보세요',
        Icons.chat_bubble_outline,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _serviceRow('검사 용어가 궁금해요', Icons.help_outline, AppColors.softPink),
            const SizedBox(height: 10),
            const Text('공개된 결과의 용어와 설명을 확인해요.', style: TextStyle(height: 1.5)),
          ],
        ),
      ),
      _card(
        '일상 속 건강관리',
        Icons.local_pharmacy_outlined,
        const Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [Text('처방 확인'), Text('알림 확인'), Text('주변 약국')],
        ),
      ),
    ],
  };

  Widget _card(String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.lightBlue),
      boxShadow: const [
        BoxShadow(
          color: Color(0x081E3A8A),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 21, color: AppColors.blue),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget _serviceRow(String text, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.navy),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.navy)),
        ),
      ],
    ),
  );

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 28,
          color: AppColors.navy,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

/// A separate Flutter-drawn bubble lets the dots move independently of BOMI.
class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter(this.progress, this.reduced);
  final double progress;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 12),
      const Radius.circular(13),
    );
    final tail = Path()
      ..moveTo(12, size.height - 15)
      ..lineTo(8, size.height - 1)
      ..quadraticBezierTo(22, size.height - 6, 26, size.height - 15)
      ..close();
    // Union avoids opposite path winding cutting a gap through the body.
    final bubble = Path.combine(
      PathOperation.union,
      Path()..addRRect(body),
      tail,
    );
    canvas.drawShadow(bubble, AppColors.pink.withValues(alpha: .35), 3, false);
    canvas.drawPath(
      bubble,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFCDD8), AppColors.pink],
        ).createShader(Offset.zero & size),
    );
    for (var i = 0; i < 3; i++) {
      final phase = ((progress - i * .18) / .40).clamp(0.0, 1.0);
      final lift = reduced ? 0.0 : math.sin(phase * math.pi) * 4;
      canvas.drawCircle(
        Offset(18 + i * 13, 21 - lift),
        3.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      progress != oldDelegate.progress || reduced != oldDelegate.reduced;
}

/// Short scene-specific accents finish with the entrance; no idle floating.
class _ArrivalEffectPainter extends CustomPainter {
  const _ArrivalEffectPainter(this.scene, this.progress, this.reduced);
  final int scene;
  final double progress;
  final bool reduced;

  // Each accent has its own start time and lifetime within the entrance.
  double _time(double delay, double duration) =>
      ((progress - delay) / duration).clamp(0.0, 1.0);
  double _fade(double t) =>
      t <= 0 || t >= 1 ? 0 : math.sin(t * math.pi).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (reduced || progress <= 0 || progress >= 1) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final cx = size.width / 2;
    switch (scene) {
      case 0:
        // Greeting: three small glints fan out next to the raised hand.
        for (var i = 0; i < 3; i++) {
          final t = _time(i * .16, .55);
          final origin = Offset(cx + 48 + i * 15.0, 70 - i * 18.0);
          final point = origin + Offset(t * (8 + i * 3), -t * 9);
          final radius = (3 + i) * _fade(t);
          final glint = Path()
            ..moveTo(point.dx, point.dy - radius * 1.5)
            ..quadraticBezierTo(
              point.dx + radius * .25,
              point.dy - radius * .2,
              point.dx + radius,
              point.dy,
            )
            ..quadraticBezierTo(
              point.dx + radius * .25,
              point.dy + radius * .2,
              point.dx,
              point.dy + radius * 1.5,
            )
            ..quadraticBezierTo(
              point.dx - radius * .25,
              point.dy + radius * .2,
              point.dx - radius,
              point.dy,
            )
            ..quadraticBezierTo(
              point.dx - radius * .25,
              point.dy - radius * .2,
              point.dx,
              point.dy - radius * 1.5,
            );
          canvas.drawPath(
            glint,
            Paint()..color = AppColors.pink.withValues(alpha: _fade(t) * .85),
          );
        }
      case 1:
        // Login: two soft ripples spread out from beneath BOMI's feet.
        for (var i = 0; i < 2; i++) {
          final t = _time(i * .22, .70);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, size.height - 14 - t * 6),
              width: 45 + t * 155,
              height: 10 + t * 24,
            ),
            Paint()
              ..color = AppColors.blue.withValues(alpha: _fade(t) * .35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5 - t,
          );
        }
      case 2:
        // Reservation: a short dotted trail follows the sideways entrance.
        for (var i = 0; i < 6; i++) {
          final t = _time(i * .065, .58);
          final x = cx - 108 + t * 74;
          final y = 110 - math.sin(t * math.pi) * 24 + i * 4;
          canvas.drawCircle(
            Offset(x, y),
            2.5 - i * .2,
            Paint()
              ..color = (i.isEven ? AppColors.blue : AppColors.pink).withValues(
                alpha: _fade(t) * .65,
              ),
          );
        }
      case 3:
        // Examination: a narrow scan passes downward, visible beside the body.
        final t = _time(.08, .80);
        final y = 22 + t * 115;
        final bounds = Rect.fromLTWH(cx - 91, y - 5, 182, 10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(bounds, const Radius.circular(5)),
          Paint()
            ..shader = LinearGradient(
              colors: [
                AppColors.blue.withValues(alpha: 0),
                AppColors.blue.withValues(alpha: _fade(t) * .45),
                AppColors.blue.withValues(alpha: 0),
              ],
            ).createShader(bounds),
        );
        final edge = Paint()
          ..color = AppColors.blue.withValues(alpha: _fade(t) * .65)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (final x in [cx - 88, cx + 88]) {
          canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), edge);
        }
      case 4:
        // Report: small paper-like flecks gather overhead then fan out.
        for (var i = 0; i < 5; i++) {
          final t = _time(.05 + i * .08, .60);
          final direction = (i - 2).toDouble();
          final x = cx + direction * (8 + t * 30);
          final y = 18 + (direction.abs() * 6) - math.sin(t * math.pi) * 11;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(direction * (.12 + t * .25));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-2, -4, 4, 8),
              const Radius.circular(1.5),
            ),
            Paint()
              ..color = (i.isEven ? AppColors.blue : AppColors.pink).withValues(
                alpha: _fade(t) * .70,
              ),
          );
          canvas.restore();
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArrivalEffectPainter oldDelegate) =>
      scene != oldDelegate.scene ||
      progress != oldDelegate.progress ||
      reduced != oldDelegate.reduced;
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.lightBlue
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        grid,
      );
    }
    final line = Path()..moveTo(0, size.height * .75);
    const values = [.75, .50, .62, .35, .42, .18];
    for (var i = 1; i < values.length; i++) {
      line.lineTo(
        size.width * i / (values.length - 1),
        size.height * values[i],
      );
    }
    final metric = line.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = AppColors.blue
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter(this.progress, this.reduced);
  final double progress;
  final bool reduced;
  @override
  void paint(Canvas canvas, Size size) {
    final fade = reduced ? 1.0 : math.sin(progress * math.pi).clamp(0.0, 1.0);
    for (var i = 0; i < 18; i++) {
      final angle = i * math.pi * 2 / 18;
      final radius = 30 + progress * 85;
      final point = Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height / 2 + math.sin(angle) * radius * .6,
      );
      canvas.drawCircle(
        point,
        i.isEven ? 3 : 2,
        Paint()
          ..color = (i.isEven ? AppColors.pink : AppColors.blue).withValues(
            alpha: fade,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      progress != oldDelegate.progress || reduced != oldDelegate.reduced;
}
