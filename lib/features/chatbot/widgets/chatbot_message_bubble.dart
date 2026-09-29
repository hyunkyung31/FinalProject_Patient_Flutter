import 'package:flutter/material.dart';

import '../model/chatbot_message.dart';

class ChatbotMessageBubble extends StatelessWidget {
  const ChatbotMessageBubble({super.key, required this.message});

  final ChatbotMessage message;

  static const _bomiAsset = 'assets/images/bomi/bomi_chatbot.png';

  @override
  Widget build(BuildContext context) {
    final isPatient = message.isPatient;
    final scheme = Theme.of(context).colorScheme;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 285),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: isPatient
            ? scheme.primary
            : scheme.primary.withValues(alpha: 0.07),
        border: isPatient
            ? null
            : Border.all(color: scheme.primary.withValues(alpha: 0.10)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isPatient ? 20 : 7),
          bottomRight: Radius.circular(isPatient ? 7 : 20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.messageText,
            style: TextStyle(
              color: isPatient ? scheme.onPrimary : scheme.onSurface,
              height: 1.5,
            ),
          ),
          if (!isPatient && message.normalizedSafetyStatus == 'ESCALATED') ...[
            const SizedBox(height: 8),
            Text(
              '??? ??? ??? ??? ? ???.',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: isPatient
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isPatient) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(_bomiAsset, fit: BoxFit.cover),
            ),
            const SizedBox(width: 9),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
