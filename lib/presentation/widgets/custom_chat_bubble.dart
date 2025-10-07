import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CustomChatBubble extends StatelessWidget {
  final String text;
  final MessageSender sender;

  const CustomChatBubble({super.key, required this.text, required this.sender});

  @override
  Widget build(BuildContext context) {
    final isUser = sender == MessageSender.user;
    final isAi = sender == MessageSender.ai;
    final theme = Theme.of(context);

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFF3D3D3D),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: SelectableText(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (isAi) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableRegion(
                  focusNode: FocusNode(),
                  selectionControls: MaterialTextSelectionControls(),
                  child: MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(
                    Icons.copy_all_rounded,
                    size: 20,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teks jawaban AI disalin ke clipboard.'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
