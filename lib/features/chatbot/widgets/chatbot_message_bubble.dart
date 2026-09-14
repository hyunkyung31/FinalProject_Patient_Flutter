import 'package:flutter/material.dart';

import '../model/chatbot_message.dart';

class ChatbotMessageBubble extends StatelessWidget {
  const ChatbotMessageBubble({super.key, required this.message});

  final ChatbotMessage message;

  @override
  Widget build(BuildContext context) {
    final isPatient = message.isPatient;
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPatient ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isPatient ? 18 : 4),
            bottomRight: Radius.circular(isPatient ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.messageText,
              style: TextStyle(
                color: isPatient ? scheme.onPrimary : scheme.onSurface,
                height: 1.4,
              ),
            ),
            if (!isPatient &&
                message.normalizedSafetyStatus == 'ESCALATED') ...[
              const SizedBox(height: 8),
              Text(
                '의료진 확인이 필요한 내용일 수 있어요.',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
