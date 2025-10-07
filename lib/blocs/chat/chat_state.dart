part of 'chat_bloc.dart';

@immutable
sealed class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final List<SelectedFile> activeFiles;
  final String? currentChatId;
  final bool isRateLimited;
  final Duration? retryAfter;

  const ChatState({
    required this.messages,
    this.activeFiles = const [],
    this.currentChatId,
    this.isRateLimited = false,
    this.retryAfter,
  });
  @override
  List<Object?> get props => [
    messages,
    activeFiles,
    currentChatId,
    isRateLimited,
    retryAfter,
  ];
}

class ChatInitial extends ChatState {
  ChatInitial() : super(messages: []);
}

class ChatLoaded extends ChatState {
  const ChatLoaded({
    required super.messages,
    required super.activeFiles,
    super.currentChatId,
  });
}
