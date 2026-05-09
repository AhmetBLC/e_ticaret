class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      text: json['text'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool isMe(String currentUserId) => senderId == currentUserId;
}
