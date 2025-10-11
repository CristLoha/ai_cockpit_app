import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomChatBubble extends StatelessWidget {
  final ChatMessage message;

  const CustomChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Container(
      margin: EdgeInsets.only(left: isUser ? 50 : 0, right: isUser ? 0 : 50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.deepPurple.withAlpha(230)
            : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: GoogleFonts.inter(
          color: isUser ? Colors.white : Colors.white.withAlpha(222),
          fontSize: 14,
        ),
      ),
    );
  }
}
