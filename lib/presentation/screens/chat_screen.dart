import 'package:ai_cockpit_app/blocs/auth/auth_cubit.dart';
import 'package:ai_cockpit_app/blocs/chat/chat_bloc.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:ai_cockpit_app/presentation/widgets/custom_chat_bubble.dart';
import 'package:ai_cockpit_app/presentation/widgets/custom_message_bar.dart';
import 'package:ai_cockpit_app/presentation/widgets/file_attachment_buble.dart';
import 'package:ai_cockpit_app/presentation/widgets/history_drawer.dart';
import 'package:ai_cockpit_app/presentation/widgets/welcome_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final filePickerState = context.watch<FilePickerCubit>().state;
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticated = authState is Authenticated;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      drawer: HistoryDrawer(
        isAuthenticated: isAuthenticated,
        onNewChat: () {
          context.read<ChatBloc>().add(ClearChatEvent());
          Navigator.pop(context);
        },
      ),
      appBar: _buildAppBar(context, authState),
      body: SafeArea(
        child: Column(
          children: [
            BlocListener<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatLoaded && state.currentChatId != null) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF212121),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, chatState) {
                        if (chatState is ChatInitial) {
                          return _buildWelcomeScreen(authState);
                        }
                        return _buildChatList(context, chatState);
                      },
                    ),
                  ),
                ),
              ),
            ),
            _buildMessageInput(context, filePickerState),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthState authState) {
    return AppBar(
      backgroundColor: const Color(0xFF2D2D2D),
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'AI Research Cockpit',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [_buildAuthButton(context), const SizedBox(width: 16)],
    );
  }

  Widget _buildAuthButton(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return GestureDetector(
            onTap: () => _showSignOutDialog(context),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Colors.deepPurple],
                ),
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(state.user.photoURL ?? ''),
                radius: 18,
              ),
            ),
          );
        }
        return ElevatedButton.icon(
          onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
          icon: const Icon(Icons.login, size: 18),
          label: Text(
            'Sign In',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeScreen(AuthState authState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.5),
          ],
        ),
      ),
      child: WelcomeMessage(authState: authState),
    );
  }

  Widget _buildChatList(BuildContext context, ChatState chatState) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
      itemCount: chatState.messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        return AnimatedSlide(
          duration: Duration(milliseconds: 300 + (index * 100)),
          offset: const Offset(0, 0),
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300 + (index * 100)),
            opacity: 1,
            child: _buildMessageItem(context, message),
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessage message) {
    switch (message.type) {
      case MessageType.attachment:
        return FileAttachmentBubble(
          title: message.text,
          originalFileName: message.originalFileName ?? message.text,
        );
      case MessageType.text:
        if (message.sender == MessageSender.system) {
          if (message.text == 'loading') {
            return _buildLoadingIndicator();
          }
          if (message.text.startsWith('Error:')) {
            return _buildErrorMessage(context, message.text);
          }
          return const SizedBox.shrink();
        }
        return CustomChatBubble(text: message.text, sender: message.sender);
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lottie/loader_animation.json',
            height: 40,
            width: 60,
          ),
          const SizedBox(width: 12),
          DefaultTextStyle(
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'AI is thinking...',
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              repeatForever: true,
            ),
          ),
        ],
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            onPressed: () =>
                context.read<ChatBloc>().add(RetryLastMessageEvent()),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    FilePickerState filePickerState,
  ) {
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
        onSend: (text) => _sendMessage(context, text),
        onAttach: () => context.read<FilePickerCubit>().pickFiles(),
        selectedFileNames: filePickerState.selectedFiles
            .map((f) => f.fileName)
            .toList(),
        onRemoveFile: (fileName) =>
            context.read<FilePickerCubit>().removeFile(fileName),
      ),
    );
  }

  void _sendMessage(BuildContext context, String text) {
    final filePickerState = context.read<FilePickerCubit>().state;
    final chatState = context.read<ChatBloc>().state;

    final question = text.trim().isEmpty
        ? "Berikan ringkasan dari dokumen ini."
        : text.trim();

    if (filePickerState.selectedFiles.isNotEmpty) {
      context.read<ChatBloc>().add(
        SendMessageWithFilesEvent(
          question: question,
          files: filePickerState.selectedFiles,
        ),
      );
      context.read<FilePickerCubit>().clearFiles();
    } else if (chatState.activeFiles.isNotEmpty) {
      context.read<ChatBloc>().add(SendFollowUpMessageEvent(question));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Harap pilih setidaknya satu file dokumen.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Sign Out',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                context.read<AuthCubit>().signOut();
                context.read<ChatBloc>().add(ClearChatEvent());
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Keluar',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
