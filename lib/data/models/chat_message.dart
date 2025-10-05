enum MessageSender { user, ai, system }

enum MessageType { text, attachment }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final MessageType type;

  ChatMessage({
    required this.text,
    required this.sender,
    this.type = MessageType.text,
  });
}
