import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';

/// Lightweight per-group chat thread. Backed by [MockGroupsRepository] /
/// [FirestoreGroupsRepository] (same `useFirebase` switch as everything
/// else) rather than the standalone Real-Time Chat system (item #7 in the
/// roadmap) — that feature adds read receipts, typing indicators, voice
/// notes, etc. across private/group/guide/support threads. This screen
/// gives group members a working text thread today; it can be pointed at
/// that richer backend later without changing this UI.
class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupTitle;
  const GroupChatScreen({super.key, required this.groupId, required this.groupTitle});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    ref.read(groupsActionsProvider).sendChatMessage(widget.groupId, text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(groupChatProvider(widget.groupId));
    final myUid = ref.watch(currentUserProvider)?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupTitle)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(child: Text('Could not load messages.')),
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isSystem = m.senderUid == 'system';
                    final isMe = m.senderUid == myUid;
                    if (isSystem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(m.text, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                        ),
                      );
                    }
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              Text(m.senderName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isMe ? Colors.white70 : AppColors.primary)),
                            Text(m.text, style: TextStyle(color: isMe ? Colors.white : null)),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('h:mm a').format(m.timestamp),
                              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Message the group\u2026'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
