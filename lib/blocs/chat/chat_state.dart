part of 'chat_bloc.dart';

@immutable
sealed class ChatState extends Equatable {
  final List<ChatMessage> messages;
  const ChatState({required this.messages});
  @override
  List<Object?> get props => [messages];
}

class ChatInitial extends ChatState {
  ChatInitial()
    : super(
        messages: [
          ChatMessage(
            text:
                'Halo! Silakan upload dokumen PDF atau DOCX untuk memulai analisis.',
            sender: MessageSender.ai,
          ),
        ],
      );
}

class ChatUpdate extends ChatState {
  const ChatUpdate({required super.messages});
}

class ChatLoading extends ChatState {
  const ChatLoading({required super.messages});
}

class ChatSuccess extends ChatState {
  final String answer;

  const ChatSuccess({required this.answer, required super.messages});

  @override
  List<Object?> get props => [answer];
}

class ChatFailure extends ChatState {
  final String error;

  const ChatFailure({required this.error, required super.messages});

  @override
  List<Object?> get props => [error];
}
