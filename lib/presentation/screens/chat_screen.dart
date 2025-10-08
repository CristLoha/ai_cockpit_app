import 'package:ai_cockpit_app/blocs/chat/chat_bloc.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:ai_cockpit_app/presentation/widgets/analysis_card.dart';
import 'package:ai_cockpit_app/presentation/widgets/custom_chat_bubble.dart';
import 'package:ai_cockpit_app/presentation/widgets/custom_message_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Event `LoadChat` sudah dipanggil di `AnalysisResultScreen` sebelum navigasi ke sini.
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          'Tanya Jawab Dokumen',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF212121),
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BlocListener<ChatBloc, ChatState>(
                    listenWhen: (previous, current) =>
                        previous.messages.length < current.messages.length,
                    listener: (context, state) => _scrollToBottom(),
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, chatState) {
                        if (chatState.status == ChatStatus.loading &&
                            chatState.messages.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return _buildChatList(context, chatState.messages);
                      },
                    ),
                  ),
                ),
              ),
            ),
            _buildMessageInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, List<ChatMessage> messages) {
    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
      itemCount: messages.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          final isLoading =
              context.watch<ChatBloc>().state.status == ChatStatus.loading;
          return isLoading ? _buildLoadingIndicator() : const SizedBox.shrink();
        }
        final message = messages[index];
        return _buildMessageItem(context, message);
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessage message) {
    if (message.sender == MessageSender.system) {
      if (message.text.toLowerCase().startsWith('error:')) {
        return _buildErrorMessage(context, message.text);
      }
      return const SizedBox.shrink();
    }

    return CustomChatBubble(message: message);
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: CustomMessageBar(
        hintText: 'Ketik pertanyaan lanjutan...',
        // DIKOSONGKAN: `onAttach` dan `onRemoveFile` tidak diisi,
        // sehingga tombol dan chip file tidak akan muncul.
        onSend: (text) {
          if (text.trim().isNotEmpty) {
            context.read<ChatBloc>().add(SendMessage(question: text));
          }
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Lottie.asset(
        'assets/lottie/loader_animation.json',
        height: 60,
        width: 80,
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, String errorText) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              errorText.replaceFirst('Error: ', ''),
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
