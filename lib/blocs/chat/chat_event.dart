part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class SendMessageAndFileEvent extends ChatEvent {
  final String question;
  final List<Uint8List> fileBytesList;
  final List<String> fileNameList;

  const SendMessageAndFileEvent({
    required this.question,
    required this.fileBytesList,
    required this.fileNameList,
  });

  @override
  List<Object> get props => [question, fileBytesList, fileNameList];
}

class RetryLastMessageEvent extends ChatEvent {}
