import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService apiService;

  ChatEvent? _lastEvent;

  ChatBloc({required this.apiService}) : super(ChatInitial()) {
    on<SendMessageWithFilesEvent>(_onSendMessageWithFiles);
    on<SendFollowUpMessageEvent>(_onSendFollowUpMessage);
    on<RetryLastMessageEvent>(_onRetry);
    on<ClearChatEvent>(_onClearChat);
  }

  void _onSendMessageWithFiles(
    SendMessageWithFilesEvent event,
    Emitter<ChatState> emit,
  ) async {
    _lastEvent = event;
    await _handleMessageSending(
      event.question,
      event.files,
      emit,
      isNewFiles: true,
    );
  }

  void _onSendFollowUpMessage(
    SendFollowUpMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    _lastEvent = event;
    await _handleMessageSending(
      event.question,
      state.activeFiles,
      emit,
      isNewFiles: false,
    );
  }

  void _onRetry(RetryLastMessageEvent event, Emitter<ChatState> emit) async {
    if (_lastEvent != null) {
      final newMessages = List<ChatMessage>.from(state.messages)..removeLast();
      emit(ChatLoaded(messages: newMessages, activeFiles: state.activeFiles));

      add(_lastEvent!);
    }
  }

  Future<void> _handleMessageSending(
    String question,
    List<SelectedFile> files,
    Emitter<ChatState> emit, {
    required bool isNewFiles,
  }) async {
    if (files.isEmpty) return;

    final userMessage = ChatMessage(text: question, sender: MessageSender.user);
    final loadingMessage = ChatMessage(
      text: 'loading',
      sender: MessageSender.system,
    );

    final attachmentMessages = isNewFiles
        ? files
              .map(
                (f) => ChatMessage(
                  text: f.fileName,
                  sender: MessageSender.system,
                  type: MessageType.attachment,
                ),
              )
              .toList()
        : <ChatMessage>[];

    final currentMessages = List<ChatMessage>.from(state.messages)
      ..addAll(attachmentMessages)
      ..add(userMessage)
      ..add(loadingMessage);

    emit(ChatLoaded(messages: currentMessages, activeFiles: files));

    try {
      final answer = await apiService.uploadDocumentAndGetAnswer(
        fileBytesList: files.map((f) => f.fileBytes).toList(),
        fileNameList: files.map((f) => f.fileName).toList(),
        question: question,
      );
      final successMessages = List<ChatMessage>.from(currentMessages)
        ..removeLast()
        ..add(ChatMessage(text: answer, sender: MessageSender.ai));
      emit(ChatLoaded(messages: successMessages, activeFiles: files));
    } catch (e) {
      final humanFriendlyError = _mapErrorToMessage(e);
      final failureMessages = List<ChatMessage>.from(currentMessages)
        ..removeLast()
        ..add(
          ChatMessage(
            text: 'Error: $humanFriendlyError',
            sender: MessageSender.system,
          ),
        );
      emit(ChatLoaded(messages: failureMessages, activeFiles: files));
    }
  }

  String _mapErrorToMessage(Object e) {
    final errorMessage = e.toString().toLowerCase();

    if (errorMessage.contains('batas penggunaan tamu tercapai')) {
      return 'Batas penggunaan tamu tercapai. Silakan Sign In untuk melanjutkan.';
    }

    if (errorMessage.contains('connection refused') ||
        errorMessage.contains('failed to connect')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    } else if (errorMessage.contains('tidak ada file yang diunggah')) {
      return 'Gagal mengirim file. Silakan coba pilih ulang file Anda.';
    } else if (errorMessage.contains('dokumen terlalu panjang')) {
      return 'Total ukuran dokumen terlalu besar. Coba kurangi jumlah atau ukuran file.';
    } else {
      // Untuk semua error lain yang tidak terduga
      return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
    }
  }

  void _onClearChat(ClearChatEvent event, Emitter<ChatState> emit) {
    emit(ChatInitial());
  }
}
