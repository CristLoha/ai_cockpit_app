import 'dart:typed_data';
import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../data/chat_message.dart';
part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService apiService;

  SendMessageAndFileEvent? _lastFailedEvent;

  ChatBloc({required this.apiService}) : super(ChatInitial()) {
    on<SendMessageAndFileEvent>(_onSendMessageAndFile);
    on<RetryLastMessageEvent>(_onRetryLastMessage);
  }

  void _onSendMessageAndFile(
    SendMessageAndFileEvent event,
    Emitter<ChatState> emit,
  ) async {
    final attachmentMessage = event.fileNameList
        .map(
          (name) => ChatMessage(
            text: name,
            sender: MessageSender.system,
            type: MessageType.attachment,
          ),
        )
        .toList();
    final userMessage = ChatMessage(
      text: event.question,
      sender: MessageSender.user,
    );
    final loadingMessage = ChatMessage(
      text: 'loading',
      sender: MessageSender.system,
    );

    final currentMessages = List<ChatMessage>.from(state.messages)
      ..addAll(attachmentMessage)
      ..add(userMessage)
      ..add(loadingMessage);
    emit(ChatUpdate(messages: currentMessages));
    try {
      final answer = await apiService.uploadDocumentAndGetAnswer(
        fileBytesList: event.fileBytesList,
        fileNameList: event.fileNameList,
        question: event.question,
      );
      final successMessages = List<ChatMessage>.from(currentMessages)
        ..removeLast()
        ..add(ChatMessage(text: answer, sender: MessageSender.ai));
      emit(ChatUpdate(messages: successMessages));
      _lastFailedEvent = null;
    } catch (e) {
      _lastFailedEvent = null;
      final failureMessages = List<ChatMessage>.from(currentMessages)
        ..removeLast()
        ..add(
          ChatMessage(
            text: 'Error: ${e.toString().replaceFirst("Exception: ", "")}',
            sender: MessageSender.system,
          ),
        );
      emit(ChatUpdate(messages: failureMessages));
    }
  }

  void _onRetryLastMessage(
    RetryLastMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (_lastFailedEvent != null) {
      final newMessages = List<ChatMessage>.from(state.messages)..removeLast();
      add(_lastFailedEvent!);
      emit(ChatUpdate(messages: newMessages));
    }
  }
}
