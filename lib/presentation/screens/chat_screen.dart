import 'package:ai_cockpit_app/blocs/chat/chat_bloc.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/data/chat_message.dart';
import 'package:ai_cockpit_app/presentation/widgets/custom_chat_bubble.dart';
import 'package:ai_cockpit_app/presentation/widgets/custom_message_bar.dart';
import 'package:ai_cockpit_app/presentation/widgets/file_attachment_buble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  void _sendMessage(
    BuildContext context,
    String text,
    FilePickerState fileState,
  ) {
    if (fileState.selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih setidaknya satu file dokumen.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    context.read<ChatBloc>().add(
      SendMessageAndFileEvent(
        question: text.trim().isEmpty
            ? "Berikan ringkasan dari semua dokumen ini."
            : text,
        fileBytesList: fileState.selectedFiles.map((f) => f.fileBytes).toList(),
        fileNameList: fileState.selectedFiles.map((f) => f.fileName).toList(),
      ),
    );

    context.read<FilePickerCubit>().clearFiles();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = context.watch<FilePickerCubit>().state;

    return Scaffold(
      backgroundColor: const Color(0xFF252525),
      appBar: AppBar(
        title: const Text('AI Research Cockpit'),
        centerTitle: true,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, chatState) {
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
                                          message.text,
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
              onSend: (text) => _sendMessage(context, text, fileState),
              onAttach: () => context.read<FilePickerCubit>().pickFiles(),
              selectedFileNames: fileState.selectedFiles
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
}
