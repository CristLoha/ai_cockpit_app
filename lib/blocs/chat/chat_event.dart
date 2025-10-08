part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class LoadChat extends ChatEvent {
  final String chatId;
  const LoadChat(this.chatId);
}

class SendMessage extends ChatEvent {
  final String question;
  const SendMessage({required this.question});
}

class ClearChat extends ChatEvent {}

class AddSystemMessage extends ChatEvent {
  final ChatMessage message;
  const AddSystemMessage(this.message);
}
