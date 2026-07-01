enum SupportChatSender { user, admin }

class SupportChatMessage {
  final String id;
  final String sender; // user ID or 'admin'
  final SupportChatSender senderType;
  final String text;
  final DateTime timestamp;

  const SupportChatMessage({
    required this.id,
    required this.sender,
    required this.senderType,
    required this.text,
    required this.timestamp,
  });

  factory SupportChatMessage.fromJson(Map<String, dynamic> json) => SupportChatMessage(
        id: json['id'] as String,
        sender: json['sender'] as String,
        senderType: json['senderType'] == 'admin' ? SupportChatSender.admin : SupportChatSender.user,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'senderType': senderType.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };
}

class SupportTicket {
  final String id;
  final String userId;
  final String destinationName;
  final String tripId;
  final List<SupportChatMessage> messages;
  final DateTime createdAt;
  final bool isResolved;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.destinationName,
    required this.tripId,
    required this.messages,
    required this.createdAt,
    this.isResolved = false,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        userId: json['userId'] as String,
        destinationName: json['destinationName'] as String,
        tripId: json['tripId'] as String,
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((e) => SupportChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isResolved: json['isResolved'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'destinationName': destinationName,
        'tripId': tripId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isResolved': isResolved,
      };
}
