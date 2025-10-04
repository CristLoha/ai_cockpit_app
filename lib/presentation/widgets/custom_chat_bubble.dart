import 'package:ai_cockpit_app/data/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CustomChatBubble extends StatelessWidget {
  final String text;
  final MessageSender sender;
  const CustomChatBubble({super.key, required this.text, required this.sender});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    CrossAxisAlignment alignment;
    Color bubbleColor;

    switch (sender) {
      case MessageSender.user:
        alignment = CrossAxisAlignment.end;
        bubbleColor = theme.colorScheme.secondary;
        break;
      case MessageSender.ai:
        alignment = CrossAxisAlignment.center;
        bubbleColor = const Color(0xFF37474F);
        break;
      case MessageSender.system:
        alignment = CrossAxisAlignment.center;
        bubbleColor = Colors.transparent;
        break;
    }

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: sender == MessageSender.ai
                ? MediaQuery.of(context).size.width * 0.85
                : MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: MarkdownBody(
            data: text,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium!.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
