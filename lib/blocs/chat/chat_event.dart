part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class SendMessageWithFilesEvent extends ChatEvent {
  final String question;
  final List<SelectedFile> files;
  const SendMessageWithFilesEvent({
    required this.question,
    required this.files,
  });
  @override
  List<Object> get props => [question, files];
}

class SendFollowUpMessageEvent extends ChatEvent {
  final String question;
  const SendFollowUpMessageEvent(this.question);
  @override
  List<Object> get props => [question];
}

class RetryLastMessageEvent extends ChatEvent {}

class ClearChatEvent extends ChatEvent {}
