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
import 'package:lottie/lottie.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final filePickerState = context.watch<FilePickerCubit>().state;
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticated = authState is Authenticated;

    return Scaffold(
      backgroundColor: const Color(0xFF252525),
      drawer: HistoryDrawer(
        isAuthenticated: isAuthenticated,
        onNewChat: () {
          context.read<ChatBloc>().add(ClearChatEvent());
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        title: const Text('AI Research Cockpit'),

        centerTitle: true,
        elevation: 1,
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return GestureDetector(
                  onTap: () => _showSignOutDialog(context),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(state.user.photoURL ?? ''),
                    radius: 18,
                  ),
                );
              }
              return TextButton(
                onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
                child: Text('Sign In', style: TextStyle(color: Colors.white)),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, chatState) {
                  if (chatState is ChatInitial) {
                    return WelcomeMessage(authState: authState);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20.0,
                      horizontal: 12.0,
                    ),
                    itemCount: chatState.messages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12.0),
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];

                      switch (message.type) {
                        case MessageType.attachment:
                          return FileAttachmentBubble(fileName: message.text);
                        case MessageType.text:
                          if (message.sender == MessageSender.system) {
                            if (message.text == 'loading') {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Lottie.asset(
                                    'assets/lottie/loading.json',
                                    height: 90,
                                  ),
                                ],
                              );
                            }
                            if (message.text.startsWith('Error:')) {
                              return Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          message.text.replaceFirst(
                                            'Error: ',
                                            '',
                                          ),
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () => context
                                            .read<ChatBloc>()
                                            .add(RetryLastMessageEvent()),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return CustomChatBubble(
                            text: message.text,
                            sender: message.sender,
                          );
                      }
                    },
                  );
                },
              ),
            ),
            CustomMessageBar(
              onSend: (text) => _sendMessage(context, text),
              onAttach: () => context.read<FilePickerCubit>().pickFiles(),
              selectedFileNames: filePickerState.selectedFiles
                  .map((f) => f.fileName)
                  .toList(),
              onRemoveFile: (fileName) =>
                  context.read<FilePickerCubit>().removeFile(fileName),
            ),
          ],
        ),
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
        const SnackBar(
          content: Text('Harap pilih setidaknya satu file dokumen.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Apakah Anda yakin ingin keluar?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                context.read<AuthCubit>().signOut();

                context.read<ChatBloc>().add(ClearChatEvent());
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
