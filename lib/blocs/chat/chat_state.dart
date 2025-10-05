part of 'chat_bloc.dart';

@immutable
sealed class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final List<SelectedFile> activeFiles;

  const ChatState({required this.messages, this.activeFiles = const []});
  @override
  List<Object?> get props => [messages, activeFiles];
}

class ChatInitial extends ChatState {
  ChatInitial()
    : super(
        messages: [
          ChatMessage(
            text: 'Halo! Silakan upload dokumen untuk memulai analisis.',
            sender: MessageSender.ai,
          ),
        ],
      );
}

class ChatLoaded extends ChatState {
  const ChatLoaded({required super.messages, required super.activeFiles});
}
