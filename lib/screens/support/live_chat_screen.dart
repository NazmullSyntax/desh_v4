import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/admin_contact.dart';
import '../../core/router/app_router.dart';
import '../../models/support_ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';

class LiveChatScreen extends ConsumerStatefulWidget {
  final String destinationName;
  final String tripId;

  const LiveChatScreen({super.key, required this.destinationName, required this.tripId});

  @override
  ConsumerState<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends ConsumerState<LiveChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<SupportChatMessage> _pendingMessages = [];
  String? _lastDebugMessage;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    bool sent = false;
    try {
      sent = await ref.read(supportActionsProvider).addUserMessage(
        destinationName: widget.destinationName,
        tripId: widget.tripId,
        message: text,
      );
    } catch (e) {
      setState(() {
        _lastDebugMessage = 'Send error: $e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
      return;
    }

    if (!sent) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send messages.')),
      );
      return;
    }

    // Optimistically show the message while Firestore updates propagate.
    final user = ref.read(currentUserProvider);
    final pending = SupportChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      sender: user?.uid ?? 'unknown',
      senderType: SupportChatSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _pendingMessages.add(pending);
      _lastDebugMessage = 'Message queued (optimistic)';
    });

    // Ask Riverpod to refresh the tickets stream; this can make new
    // messages appear faster on slower connections.
    try {
      ref.refresh(userSupportTicketsProvider);
    } catch (_) {}

    _controller.clear();
    _scrollToBottom();
    setState(() {
      _lastDebugMessage = 'Message sent (awaiting server sync)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final ticketAsync = ref.watch(userSupportTicketsProvider);

    // If the user is not signed in, show a friendly prompt to sign in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.support_agent_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Sign in to start a Live Chat with support', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final ok = await ref.read(authControllerProvider.notifier).continueAsGuest();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in as guest')));
                        }
                      },
                      child: const Text('Continue as Guest'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Chat'),
      ),
      body: ticketAsync.when(
        // While the tickets stream is loading, allow the signed-in user to
        // send the first message immediately rather than blocking on the
        // stream. This avoids an indefinite spinner when Firestore is slow.
        loading: () {
          final messages = <SupportChatMessage>[];
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      buildSupportChatWelcomeMessage(
                        destinationName: widget.destinationName,
                        tripId: widget.tripId,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type your message... (stream loading) ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (tickets) {
          // Find ticket for this trip
          SupportTicket? ticket;
          try {
            ticket = tickets.firstWhere((t) => t.tripId == widget.tripId);
          } catch (e) {
            ticket = null;
          }

          final serverMessages = ticket?.messages ?? [];
          // Remove any pending messages that have been delivered (match by
          // text and timestamp proximity) to avoid duplicates.
          _pendingMessages.removeWhere((p) => serverMessages.any((s) {
                final diff = s.timestamp.difference(p.timestamp).inSeconds.abs();
                return s.text == p.text && diff < 3;
              }));

          final messages = [...serverMessages, ..._pendingMessages];

          return Column(
            children: [
              if (_lastDebugMessage != null)
                Container(
                  width: double.infinity,
                  color: Colors.yellow.shade100,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Debug: ${_lastDebugMessage!}',
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            buildSupportChatWelcomeMessage(
                              destinationName: widget.destinationName,
                              tripId: widget.tripId,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isUser = msg.sender != 'admin';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              decoration: BoxDecoration(
                                color: isUser ? AppColors.primary : Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(color: isUser ? Colors.white : null),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
