/// Uma mensagem da conversa com o avatar.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    return ChatMessage(
      text: json['text']! as String,
      // `isUser` era o nome do campo na v1; mantido para ler dados antigos.
      fromUser: (json['fromUser'] ?? json['isUser'])! as bool,
      sentAt: DateTime.parse((json['sentAt'] ?? json['timestamp'])! as String),
    );
  }

  final String text;
  final bool fromUser;
  final DateTime sentAt;

  Map<String, Object?> toJson() => {
    'text': text,
    'fromUser': fromUser,
    'sentAt': sentAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is ChatMessage &&
      other.text == text &&
      other.fromUser == fromUser &&
      other.sentAt == sentAt;

  @override
  int get hashCode => Object.hash(text, fromUser, sentAt);
}
