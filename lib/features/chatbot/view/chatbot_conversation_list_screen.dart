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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('두근 건강 상담')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _createConversation,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: _creating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onPrimary,
                ),
              )
            : const Icon(Icons.add_comment_rounded),
        label: const Text(
          '새 상담 시작',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    final scheme = Theme.of(context).colorScheme;

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
                    Icon(
                      Icons.error_outline_rounded,
                      size: 42,
                      color: scheme.primary,
                    ),
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
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 120),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.06),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/bomi/bomi_chatbot.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '보미와 이야기를 시작해 보세요',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '검사 결과와 건강 정보에 대해\n궁금한 내용을 편하게 물어보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/bomi/bomi_chatbot.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '보미와 건강 이야기를 나눠보세요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '이전 상담을 이어가거나 새 상담을 시작할 수 있어요.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._conversations.map((conversation) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: conversation.isActive
                  ? scheme.primary.withValues(alpha: 0.045)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                onTap: () {
                  _openConversation(conversation);
                },
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.10),
                  ),
                  child: Icon(
                    conversation.isActive
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.history_rounded,
                    color: scheme.primary,
                    size: 23,
                  ),
                ),
                title: Text(
                  conversation.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    conversation.isActive ? '상담 진행 중' : '종료된 상담',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
