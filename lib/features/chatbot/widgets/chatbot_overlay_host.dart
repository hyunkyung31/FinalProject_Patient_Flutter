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

class ChatbotOverlayHost extends StatelessWidget {
  const ChatbotOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: ChatbotOverlayController.instance.visible,
          builder: (context, visible, _) {
            if (!visible) {
              return const SizedBox.shrink();
            }

            return SafeArea(
              minimum: const EdgeInsets.only(right: 16, bottom: 20),
              child: Align(
                alignment: Alignment.bottomRight,
                child: ChatbotFloatingLauncher(
                  onPressed: ChatbotOverlayController.instance.open,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
