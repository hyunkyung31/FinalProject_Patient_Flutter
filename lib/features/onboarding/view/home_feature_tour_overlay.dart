import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_preferences.dart';

enum _TourShape { rounded, circle }

class HomeFeatureTourOverlay extends StatefulWidget {
  const HomeFeatureTourOverlay({
    super.key,
    required this.reservationKey,
    required this.quickMenuKey,
    required this.chatbotKey,
    required this.healthTabKey,
    required this.onFinish,
    required this.onSkip,
  });

  final GlobalKey reservationKey;
  final GlobalKey quickMenuKey;
  final GlobalKey chatbotKey;
  final GlobalKey healthTabKey;
  final Future<void> Function() onFinish;
  final Future<void> Function() onSkip;

  @override
  State<HomeFeatureTourOverlay> createState() => _HomeFeatureTourOverlayState();
}

class _HomeFeatureTourOverlayState extends State<HomeFeatureTourOverlay> {
  var _index = 0;

  _TourTarget _targetForIndex() => [
    _TourTarget(
      key: widget.reservationKey,
      shape: _TourShape.rounded,
      title: '\uC608\uC57D \uD655\uC778\uACFC \uC0C8 \uC608\uC57D',
      description:
          '\uC608\uC815\uB41C \uC9C4\uB8CC \uC77C\uC815\uC744 \uD655\uC778\uD558\uACE0, \uD544\uC694\uD558\uBA74 \uC0C8 \uC608\uC57D\uC744 \uC2DC\uC791\uD560 \uC218 \uC788\uC5B4\uC694.',
    ),
    _TourTarget(
      key: widget.quickMenuKey,
      shape: _TourShape.rounded,
      title: '\uC790\uC8FC \uC4F0\uB294 \uAE30\uB2A5',
      description:
          '\uAC80\uC0AC\uACB0\uACFC, AI \uB9AC\uD3EC\uD2B8, \uCC98\uBC29 \uC870\uD68C, \uC8FC\uBCC0 \uC57D\uAD6D\uC744 \uD55C\uBC88\uC5D0 \uCC3E\uC744 \uC218 \uC788\uC5B4\uC694.',
    ),
    _TourTarget(
      key: widget.chatbotKey,
      shape: _TourShape.circle,
      title: '\uBCF4\uBBF8\uC5D0\uAC8C \uBB3C\uC5B4\uBCF4\uC138\uC694',
      description:
          '\uC0C1\uB2E8 \uCC57\uBD07\uC5D0\uC11C \uC9C4\uB8CC\uC640 \uAC74\uAC15\uC5D0 \uAD00\uD55C \uAD81\uAE08\uD55C \uC810\uC744 \uBC14\uB85C \uBB3C\uC5B4\uBCFC \uC218 \uC788\uC5B4\uC694.',
    ),
    _TourTarget(
      key: widget.healthTabKey,
      shape: _TourShape.circle,
      title: '\uD558\uB2E8 \uD0ED\uC73C\uB85C \uC26C\uAC8C \uC774\uB3D9',
      description:
          '\uD558\uB2E8 \uD0ED\uC5D0\uC11C \uC608\uC57D, \uAC80\uC0AC\uACB0\uACFC, \uD648, \uAC74\uAC15\uAD00\uB9AC, \uB0B4 \uC815\uBCF4\uB97C \uC5B8\uC81C\uB4E0 \uC624\uAC08 \uC218 \uC788\uC5B4\uC694.',
    ),
  ][_index];

  Rect? _rectFor(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  void _next() {
    if (_index == 3) {
      widget.onFinish();
      return;
    }
    setState(() => _index += 1);
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetForIndex();
    final targetRect = _rectFor(target.key);
    if (targetRect == null) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    const panelHeight = 178.0;
    final panelTop =
        (targetRect.center.dy > size.height - 230
                ? targetRect.top - panelHeight - 26
                : targetRect.bottom + 42)
            .clamp(70.0, size.height - panelHeight - 24);
    final panelRect = Rect.fromLTWH(24, panelTop, size.width - 48, panelHeight);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TourBackdrop(targetRect, target.shape),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _TourArrow(panelRect, targetRect)),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: panelTop,
            height: panelHeight,
            child: _TourPanel(
              step: _index + 1,
              title: target.title,
              description: target.description,
              last: _index == 3,
              onNext: _next,
              onSkip: widget.onSkip,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourTarget {
  const _TourTarget({
    required this.key,
    required this.shape,
    required this.title,
    required this.description,
  });
  final GlobalKey key;
  final _TourShape shape;
  final String title;
  final String description;
}

class _TourPanel extends StatelessWidget {
  const _TourPanel({
    required this.step,
    required this.title,
    required this.description,
    required this.last,
    required this.onNext,
    required this.onSkip,
  });
  final int step;
  final String title;
  final String description;
  final bool last;
  final VoidCallback onNext;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF11264A),
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x668DE9DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD8E5),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$step / 4',
                style: const TextStyle(
                  color: Color(0xFFAFC9FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF2F6FF),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                child: const Text(
                  '\uAC74\uB108\uB6F0\uAE30',
                  style: TextStyle(color: Color(0xFFAFC9FF)),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3976E8),
                ),
                child: Text(last ? '\uC2DC\uC791\uD558\uAE30' : '\uB2E4\uC74C'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TourBackdrop extends CustomPainter {
  const _TourBackdrop(this.rect, this.shape);
  final Rect rect;
  final _TourShape shape;
  @override
  void paint(Canvas canvas, Size size) {
    final spotlight = rect.inflate(shape == _TourShape.circle ? 9 : 7);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xCC07101F),
    );
    final clear = Paint()..blendMode = BlendMode.clear;
    _draw(canvas, spotlight, clear);
    canvas.restore();
    _draw(
      canvas,
      spotlight,
      Paint()
        ..color = const Color(0xFF8DE9DE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _draw(Canvas canvas, Rect value, Paint paint) {
    if (shape == _TourShape.circle) {
      canvas.drawCircle(value.center, value.longestSide / 2, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(value, const Radius.circular(20)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TourBackdrop oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.shape != shape;
}

class _TourArrow extends CustomPainter {
  const _TourArrow(this.panelRect, this.targetRect);
  final Rect panelRect;
  final Rect targetRect;
  @override
  void paint(Canvas canvas, Size size) {
    final above = targetRect.center.dy < panelRect.center.dy;
    final x = targetRect.center.dx.clamp(
      panelRect.left + 28,
      panelRect.right - 28,
    );
    final start = Offset(x, above ? panelRect.top : panelRect.bottom);
    final end = Offset(
      targetRect.center.dx,
      above ? targetRect.bottom : targetRect.top,
    );
    final delta = end - start;
    final paint = Paint()
      ..color = const Color(0xFF8DE9DE)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(start.dx, start.dy);
    final control1 = start + delta * .32;
    final control2 = end - delta * .27;
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );
    canvas.drawPath(path, paint);
    final tangent = end - control2;
    final angle = math.atan2(tangent.dy, tangent.dx);
    for (final offset in [-.62, .62]) {
      canvas.drawLine(
        end,
        Offset(
          end.dx - math.cos(angle + offset) * 13,
          end.dy - math.sin(angle + offset) * 13,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TourArrow oldDelegate) =>
      oldDelegate.panelRect != panelRect ||
      oldDelegate.targetRect != targetRect;
}

Future<void> showHomeTourTextScalePicker(BuildContext context) async {
  final preferences = await SharedPreferences.getInstance();
  if (!context.mounted ||
      (preferences.getBool('home_text_scale_selected') ?? false)) {
    return;
  }
  var selected = AppPreferences.instance.textScale;
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 20 * selected,
                  fontWeight: FontWeight.w900,
                ),
                child: const Text(
                  '\uB098\uC5D0\uAC8C \uB9DE\uB294 \uAE00\uC528 \uD06C\uAE30\uB97C \uACE8\uB77C\uC694',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (final value in const [1.0, 1.2, 1.5])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () => setState(() => selected = value),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selected == value
                                ? const Color(0xFFDCEAFF)
                                : null,
                          ),
                          child: Text('${(value * 100).round()}%'),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final apply = await showDialog<bool>(
                    context: sheetContext,
                    builder: (dialog) => AlertDialog(
                      title: const Text(
                        '\uC120\uD0DD\uD55C \uAE00\uC528 \uD06C\uAE30\uB85C \uC801\uC6A9\uD560\uAE4C\uC694?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog, false),
                          child: const Text('\uB2E4\uC2DC \uACE0\uB974\uAE30'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialog, true),
                          child: const Text('\uC801\uC6A9'),
                        ),
                      ],
                    ),
                  );
                  if (apply != true) return;
                  await AppPreferences.instance.save(textScale: selected);
                  await preferences.setBool('home_text_scale_selected', true);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('\uC120\uD0DD \uC644\uB8CC'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
