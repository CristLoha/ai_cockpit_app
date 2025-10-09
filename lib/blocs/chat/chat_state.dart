part of 'chat_bloc.dart';

enum ChatStatus {
  initial,
  loading,
  success,
  failure,
  exporting,
  exportSuccess,
  exportFailure,
}

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? currentChatId;
  final List<SelectedFile> activeFiles;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.currentChatId,
    this.activeFiles = const [],
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? currentChatId,
    List<SelectedFile>? activeFiles,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentChatId: currentChatId ?? this.currentChatId,
      activeFiles: activeFiles ?? this.activeFiles,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    currentChatId,
    activeFiles,
    errorMessage,
  ];
}
