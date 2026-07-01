enum ChatSender { user, assistant }

/// A single message in the AI Travel Assistant conversation.
class ChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({String? text, bool? isLoading}) {
    return ChatMessage(
      id: id,
      sender: sender,
      text: text ?? this.text,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// A quick suggested prompt shown as a chip above the chat input.
class SuggestedPrompt {
  final String label;
  final String prompt;

  const SuggestedPrompt({required this.label, required this.prompt});
}
