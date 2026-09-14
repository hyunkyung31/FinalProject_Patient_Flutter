import 'package:flutter/material.dart';

class ChatbotFloatingLauncher extends StatelessWidget {
  const ChatbotFloatingLauncher({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const _assetPath = 'assets/images/bomi/bomi_chatbot.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '보미 챗봇 열기',
      child: Material(
        elevation: 8,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink.image(
            image: const AssetImage(_assetPath),
            width: 68,
            height: 68,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
