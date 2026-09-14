import 'package:flutter/material.dart';

import '../model/chatbot_conversation.dart';
import '../repository/chatbot_repository.dart';
import 'chatbot_conversation_screen.dart';

class ChatbotConversationListScreen extends StatefulWidget {
  const ChatbotConversationListScreen({super.key, required this.repository});

  final ChatbotRepository repository;

  @override
  State<ChatbotConversationListScreen> createState() =>
      _ChatbotConversationListScreenState();
}

class _ChatbotConversationListScreenState
    extends State<ChatbotConversationListScreen> {
  List<ChatbotConversation> _conversations = const [];

  bool _loading = true;
  bool _creating = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final page = await widget.repository.getConversations();

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = page.results;
        _loading = false;
      });
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

  Future<void> _createConversation() async {
    if (_creating) {
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      final conversation = await widget.repository.createConversation();

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatbotConversationScreen(
            repository: widget.repository,
            conversation: conversation,
          ),
        ),
      );

      if (mounted) {
        await _load();
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
          _creating = false;
        });
      }
    }
  }

  Future<void> _openConversation(ChatbotConversation conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatbotConversationScreen(
          repository: widget.repository,
          conversation: conversation,
        ),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 건강 챗봇')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _createConversation,
        icon: _creating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_comment_outlined),
        label: const Text('새 대화'),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: Center(
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
            ),
          ),
        ],
      );
    }

    if (_conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 420,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 54),
                    SizedBox(height: 16),
                    Text(
                      '아직 대화가 없어요.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '새 대화를 시작해 건강 정보에 대해 물어보세요.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: _conversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final conversation = _conversations[index];

        return Card(
          child: ListTile(
            onTap: () {
              _openConversation(conversation);
            },
            leading: CircleAvatar(
              child: Icon(
                conversation.isActive
                    ? Icons.chat_bubble_outline
                    : Icons.history,
              ),
            ),
            title: Text(
              conversation.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(conversation.isActive ? '대화 진행 중' : '종료된 대화'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
