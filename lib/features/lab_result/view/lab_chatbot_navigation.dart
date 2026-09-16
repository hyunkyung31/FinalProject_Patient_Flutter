import 'package:flutter/material.dart';

import '../../chatbot/model/chatbot_conversation.dart';
import '../../chatbot/repository/chatbot_repository.dart';
import '../../chatbot/view/chatbot_conversation_screen.dart';

const _labConversationTitle = '혈액검사 결과 상담';

Future<ChatbotConversation> _getOrCreateLabConversation(
  ChatbotRepository repository,
) async {
  var page = 1;

  while (page <= 100) {
    final result = await repository.getConversations(
      status: 'ACTIVE',
      page: page,
    );

    for (final conversation in result.results) {
      if (conversation.isActive &&
          conversation.title?.trim() == _labConversationTitle) {
        return conversation;
      }
    }

    if (!result.hasNext) {
      break;
    }

    page += 1;
  }

  return repository.createConversation(title: _labConversationTitle);
}

Future<void> openLabChatbot({
  required BuildContext context,
  required ChatbotRepository repository,
  required String message,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final conversation = await _getOrCreateLabConversation(repository);

    await repository.sendMessage(
      conversationId: conversation.id,
      messageText: message,
    );

    if (!context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatbotConversationScreen(
          repository: repository,
          conversation: conversation,
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(chatbotErrorMessage(error))));
  }
}
