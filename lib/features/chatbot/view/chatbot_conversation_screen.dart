import 'package:flutter/material.dart';

import '../model/chatbot_conversation.dart';
import '../model/chatbot_message.dart';
import '../repository/chatbot_repository.dart';
import '../widgets/chatbot_message_bubble.dart';

class ChatbotConversationScreen extends StatefulWidget {
  const ChatbotConversationScreen({
    super.key,
    required this.repository,
    required this.conversation,
  });

  final ChatbotRepository repository;
  final ChatbotConversation conversation;

  @override
  State<ChatbotConversationScreen> createState() =>
      _ChatbotConversationScreenState();
}

class _ChatbotConversationScreenState extends State<ChatbotConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  ChatbotConversationDetail? _detail;

  bool _loading = true;
  bool _sending = false;
  bool _closing = false;

  String? _errorMessage;

  ChatbotConversation get _conversation {
    return _detail?.conversation ?? widget.conversation;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final detail = await widget.repository.getConversation(
        widget.conversation.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _loading = false;
        _errorMessage = null;
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = chatbotErrorMessage(error);
      });
    }
  }

  Future<void> _send() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty || _sending || !_conversation.isActive) {
      return;
    }

    setState(() {
      _sending = true;
    });

    FocusScope.of(context).unfocus();

    try {
      final result = await widget.repository.sendMessage(
        conversationId: _conversation.id,
        messageText: messageText,
      );

      _messageController.clear();

      await _load(showLoading: false);

      if (!mounted) {
        return;
      }

      // 챗봇 서비스가 아직 연결되지 않은 경우
      if (!result.completed) {
        final detail = result.detail?.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detail != null && detail.isNotEmpty
                  ? detail
                  : 'AI 답변 서비스에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(chatbotErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _closeConversation() async {
    if (_closing || !_conversation.isActive) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('대화를 종료할까요?'),
          content: const Text(
            '종료한 대화는 다시 메시지를 보낼 수 없지만 '
            '이전 대화 내용은 계속 확인할 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('종료'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _closing = true;
    });

    try {
      await widget.repository.closeConversation(_conversation.id);

      await _load(showLoading: false);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('대화가 종료됐어요.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(chatbotErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _closing = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_conversation.displayTitle),
        actions: [
          if (_conversation.isActive)
            IconButton(
              tooltip: '대화 종료',
              onPressed: _closing ? null : _closeConversation,
              icon: _closing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.stop_circle_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          const _ChatbotNotice(),
          Expanded(child: _buildContent()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final messages = _detail?.messages ?? const <ChatbotMessage>[];

    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48),
              SizedBox(height: 14),
              Text(
                '궁금한 내용을 입력해 주세요.',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                '공개된 검사 결과나 예약 정보에 대해 질문할 수 있어요.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatbotMessageBubble(message: messages[index]);
      },
    );
  }

  Widget _buildComposer() {
    if (!_conversation.isActive) {
      return const SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '종료된 대화입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_sending,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력해 주세요',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: '전송',
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatbotNotice extends StatelessWidget {
  const _ChatbotNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI 건강 안내는 의료진의 진단이나 응급 진료를 대신하지 않습니다.',
              style: TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
