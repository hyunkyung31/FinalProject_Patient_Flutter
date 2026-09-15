import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chatbot_floating_launcher.dart';

typedef ChatbotOpenCallback = Future<void> Function();

class ChatbotOverlayController {
  ChatbotOverlayController._();

  static final instance = ChatbotOverlayController._();

  final ValueNotifier<bool> visible = ValueNotifier<bool>(false);

  ChatbotOpenCallback? _onOpen;
  bool _opening = false;

  void activate(ChatbotOpenCallback onOpen) {
    _onOpen = onOpen;

    if (!visible.value) {
      visible.value = true;
    }
  }

  void deactivate() {
    _onOpen = null;

    if (visible.value) {
      visible.value = false;
    }
  }

  Future<void> open() async {
    final onOpen = _onOpen;

    if (onOpen == null || _opening) {
      return;
    }

    _opening = true;
    visible.value = false;

    try {
      await onOpen();
    } finally {
      _opening = false;

      if (_onOpen != null) {
        visible.value = true;
      }
    }
  }
}

class ChatbotOverlayHost extends StatefulWidget {
  const ChatbotOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  State<ChatbotOverlayHost> createState() => _ChatbotOverlayHostState();
}

class _ChatbotOverlayHostState extends State<ChatbotOverlayHost>
    with SingleTickerProviderStateMixin {
  static const double _launcherSize = 68;
  static const double _edgePadding = 16;
  static const double _topPadding = 12;

  // 하단 네비게이션 영역과 겹치지 않도록 여유 공간을 둔다.
  static const double _bottomReserved = 88;

  Offset? _position;
  bool _dragging = false;
  bool _hintPlayed = false;

  late final AnimationController _hintController;

  @override
  void initState() {
    super.initState();

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  Offset _clampPosition(
    Offset position,
    Size size,
    EdgeInsets safePadding,
  ) {
    final minX = _edgePadding;
    final maxX = math.max(
      minX,
      size.width - _launcherSize - _edgePadding,
    );

    final minY = safePadding.top + _topPadding;
    final maxY = math.max(
      minY,
      size.height -
          safePadding.bottom -
          _bottomReserved -
          _launcherSize,
    );

    return Offset(
      position.dx.clamp(minX, maxX).toDouble(),
      position.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Offset _defaultPosition(
    Size size,
    EdgeInsets safePadding,
  ) {
    return _clampPosition(
      Offset(
        size.width - _launcherSize - _edgePadding,
        size.height -
            safePadding.bottom -
            _bottomReserved -
            _launcherSize,
      ),
      size,
      safePadding,
    );
  }

  void _playHintOnce() {
    if (!mounted || _hintPlayed) {
      return;
    }

    _hintPlayed = true;
    _hintController.forward(from: 0);
  }

  void _hideHint() {
    if (!_hintController.isAnimating) {
      return;
    }

    _hintController.stop();
    _hintController.value = 1;
  }

  double _hintOpacity(double value) {
    if (value < 0.15) {
      return (value / 0.15).clamp(0.0, 1.0).toDouble();
    }

    if (value > 0.75) {
      return ((1 - value) / 0.25).clamp(0.0, 1.0).toDouble();
    }

    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        ValueListenableBuilder<bool>(
          valueListenable: ChatbotOverlayController.instance.visible,
          builder: (context, visible, _) {
            if (!visible) {
              return const SizedBox.shrink();
            }

            if (!_hintPlayed) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _playHintOnce(),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                final safePadding = MediaQuery.paddingOf(context);

                final currentPosition = _clampPosition(
                  _position ?? _defaultPosition(size, safePadding),
                  size,
                  safePadding,
                );

                final minX = _edgePadding;
                final maxX = math.max(
                  minX,
                  size.width - _launcherSize - _edgePadding,
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: currentPosition.dx,
                      top: currentPosition.dy,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (_) {
                          _hideHint();

                          setState(() {
                            _dragging = true;
                          });
                        },
                        onPanUpdate: (details) {
                          final nextPosition = _clampPosition(
                            currentPosition + details.delta,
                            size,
                            safePadding,
                          );

                          setState(() {
                            _position = nextPosition;
                          });
                        },
                        onPanEnd: (_) {
                          final launcherCenter =
                              currentPosition.dx + (_launcherSize / 2);

                          final targetX = launcherCenter < size.width / 2
                              ? minX
                              : maxX;

                          setState(() {
                            _position = Offset(
                              targetX,
                              currentPosition.dy,
                            );
                            _dragging = false;
                          });
                        },
                        onPanCancel: () {
                          setState(() {
                            _dragging = false;
                          });
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedScale(
                              scale: _dragging ? 1.06 : 1,
                              duration: const Duration(milliseconds: 120),
                              child: ChatbotFloatingLauncher(
                                onPressed:
                                    ChatbotOverlayController.instance.open,
                              ),
                            ),
                            Positioned(
                              left: -34,
                              top: 18,
                              child: IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _hintController,
                                  builder: (context, child) {
                                    final value = _hintController.value;

                                    final movementProgress =
                                        (value / 0.75)
                                            .clamp(0.0, 1.0)
                                            .toDouble();

                                    final dx =
                                        -8 +
                                        (16 *
                                            Curves.easeInOut.transform(
                                              movementProgress,
                                            ));

                                    return Opacity(
                                      opacity: _hintOpacity(value),
                                      child: Transform.translate(
                                        offset: Offset(dx, 0),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.swipe_rounded,
                                    size: 30,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}