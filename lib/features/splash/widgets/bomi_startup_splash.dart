import 'dart:math' as math;

import 'package:flutter/material.dart';

class BomiStartupSplash extends StatefulWidget {
  const BomiStartupSplash({super.key});

  @override
  State<BomiStartupSplash> createState() => _BomiStartupSplashState();
}

class _BomiStartupSplashState extends State<BomiStartupSplash>
    with SingleTickerProviderStateMixin {
  static const _defaultFace = 'assets/images/bomi/bomi_splash_face_default.png';
  static const _blinkFace = 'assets/images/bomi/bomi_splash_face_blink.png';
  static const _smileFace = 'assets/images/bomi/bomi_splash_face_smile.png';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _faceFor(double progress) {
    // 짧은 눈 깜빡임
    if (progress >= 0.30 && progress < 0.36) {
      return _blinkFace;
    }

    // 루프 후반에는 조금 더 밝은 미소
    if (progress >= 0.64 && progress < 0.84) {
      return _smileFace;
    }

    return _defaultFace;
  }

  double _dotOpacity(double progress, int index) {
    final shifted = (progress + index * 0.17) % 1.0;
    return 0.28 + (0.72 * ((math.sin(shifted * math.pi * 2) + 1) / 2));
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final mascotSize = math.min(screen.width * 0.43, 178.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              left: -78,
              top: 62,
              child: _SoftCircle(size: 158, color: Color(0xFFF0F6FF)),
            ),
            const Positioned(
              right: -70,
              bottom: 10,
              child: _SoftCircle(size: 166, color: Color(0xFFFFF0F4)),
            ),
            const Positioned(
              right: 22,
              top: 88,
              child: _SoftCircle(size: 48, color: Color(0xFFFFF2F6)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/images/bomi/dugn_logo.png',
                    width: 110,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final progress = _controller.value;
                      final reducedMotion = MediaQuery.of(
                        context,
                      ).disableAnimations;

                      final bob = reducedMotion
                          ? 0.0
                          : math.sin(progress * math.pi * 2) * 4.0;

                      final scale = reducedMotion
                          ? 1.0
                          : 1.0 +
                                ((math.sin(progress * math.pi * 2) + 1) *
                                    0.006);

                      final asset = reducedMotion
                          ? _defaultFace
                          : _faceFor(progress);

                      return Transform.translate(
                        offset: Offset(0, bob),
                        child: Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            width: mascotSize,
                            height: mascotSize,
                            child: Image.asset(
                              asset,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '오늘도 함께할게요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF153D7A),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    '보미가 건강한 하루를 준비하고 있어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7C8BA8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3.5,
                            ),
                            child: Opacity(
                              opacity: _dotOpacity(_controller.value, index),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF48BA3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '검사 · 예약 · 건강관리 정보를 준비하는 중',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFA0ABC0),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
