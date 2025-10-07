import 'dart:async';
import 'dart:typed_data';
import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService apiService;

  ChatEvent? _lastEvent;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isRetrying = false;

  ChatBloc({required this.apiService}) : super(ChatInitial()) {
    on<SendMessageWithFilesEvent>(_onSendMessageWithFiles);
    on<SendFollowUpMessageEvent>(_onSendFollowUpMessage);
    on<RetryLastMessageEvent>(_onRetry);
    on<ClearChatEvent>(_onClearChat);
    on<LoadChatHistoryEvent>(_onLoadChatHistory);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (!results.contains(ConnectivityResult.none) &&
          _lastEvent != null &&
          !_isRetrying) {
        add(RetryLastMessageEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
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

  Future<void> _onRetry(
    RetryLastMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (_lastEvent == null || _isRetrying) return;
    if (!(_lastEvent is SendMessageWithFilesEvent ||
        _lastEvent is SendFollowUpMessageEvent)) {
      return;
    }

    _isRetrying = true;

    final loadingMessage = ChatMessage(
      text: 'loading',
      sender: MessageSender.system,
    );
    final currentMessages = List<ChatMessage>.from(state.messages);

    if (currentMessages.isNotEmpty &&
        currentMessages.last.sender == MessageSender.system &&
        currentMessages.last.text.toLowerCase().startsWith('error:')) {
      currentMessages.removeLast();
      emit(
        ChatLoaded(
          messages: [...currentMessages, loadingMessage],
          activeFiles: state.activeFiles,
        ),
      );
    } else {
      emit(
        ChatLoaded(
          messages: [...currentMessages, loadingMessage],
          activeFiles: state.activeFiles,
        ),
      );
    }

    final String question;
    final List<SelectedFile> files;
    final bool isNewFiles;

    if (_lastEvent is SendMessageWithFilesEvent) {
      final failedEvent = _lastEvent as SendMessageWithFilesEvent;
      question = failedEvent.question;
      files = failedEvent.files;
      isNewFiles = true;
    } else {
      final failedEvent = _lastEvent as SendFollowUpMessageEvent;
      question = failedEvent.question;
      files = state.activeFiles;
      isNewFiles = false;
    }

    try {
      final Map<String, dynamic> apiResult = await apiService
          .uploadDocumentAndGetAnswer(
            fileBytesList: files.map((f) => f.fileBytes).toList(),
            fileNameList: files.map((f) => f.fileName).toList(),
            question: question,
          );

      final String answer =
          apiResult['answer'] as String? ?? 'Gagal mendapatkan jawaban.';
      final List<dynamic> processedDocs =
          (apiResult['processedDocuments'] as List<dynamic>?) ?? [];

      final baseMessages = List<ChatMessage>.from(currentMessages)
        ..removeLast();

      final correctAttachmentMessages = isNewFiles
          ? processedDocs
                .map(
                  (doc) => ChatMessage(
                    text: doc['title'],
                    originalFileName: doc['originalName'],
                    sender: MessageSender.system,
                    type: MessageType.attachment,
                  ),
                )
                .toList()
          : <ChatMessage>[];

      final finalMessages = List<ChatMessage>.from(baseMessages)
        ..addAll(correctAttachmentMessages)
        ..add(ChatMessage(text: question, sender: MessageSender.user))
        ..add(ChatMessage(text: answer, sender: MessageSender.ai));

      emit(ChatLoaded(messages: finalMessages, activeFiles: files));
      _lastEvent = null;
      _isRetrying = false;
    } catch (e) {
      final humanFriendlyError = await _mapErrorToMessage(e);
      final messagesWithoutLoading = List<ChatMessage>.from(currentMessages);
      emit(
        ChatLoaded(
          messages: [
            ...messagesWithoutLoading,
            ChatMessage(
              text: 'Error: $humanFriendlyError',
              sender: MessageSender.system,
            ),
          ],
          activeFiles: state.activeFiles,
        ),
      );
      _isRetrying = false;
    }
  }

  Future<void> _handleMessageSending(
    String question,
    List<SelectedFile> files,
    Emitter<ChatState> emit, {
    required bool isNewFiles,
  }) async {
    _isRetrying = false;
    final userMessage = ChatMessage(text: question, sender: MessageSender.user);
    final loadingMessage = ChatMessage(
      text: 'loading',
      sender: MessageSender.system,
    );
    final baseMessages = state is ChatInitial
        ? <ChatMessage>[]
        : List<ChatMessage>.from(state.messages);

    emit(
      ChatLoaded(
        messages: [...baseMessages, userMessage, loadingMessage],
        activeFiles: files,
      ),
    );

    try {
      final Map<String, dynamic> apiResult = await apiService
          .uploadDocumentAndGetAnswer(
            fileBytesList: files.map((f) => f.fileBytes).toList(),
            fileNameList: files.map((f) => f.fileName).toList(),
            question: question,
          );

      final String answer =
          apiResult['answer'] as String? ?? 'Gagal mendapatkan jawaban.';
      final List<dynamic> processedDocs =
          (apiResult['processedDocuments'] as List<dynamic>?) ?? [];

      final correctAttachmentMessages = isNewFiles
          ? processedDocs
                .map(
                  (doc) => ChatMessage(
                    text: doc['title'],
                    originalFileName: doc['originalName'],
                    sender: MessageSender.system,
                    type: MessageType.attachment,
                  ),
                )
                .toList()
          : <ChatMessage>[];

      final finalMessages = List<ChatMessage>.from(baseMessages)
        ..addAll(correctAttachmentMessages)
        ..add(userMessage)
        ..add(ChatMessage(text: answer, sender: MessageSender.ai));

      emit(ChatLoaded(messages: finalMessages, activeFiles: files));
      _lastEvent = null;
    } catch (e) {
      final humanFriendlyError = await _mapErrorToMessage(e);
      final failureMessages = List<ChatMessage>.from(baseMessages)
        ..add(userMessage)
        ..add(
          ChatMessage(
            text: 'Error: $humanFriendlyError',
            sender: MessageSender.system,
          ),
        );
      emit(ChatLoaded(messages: failureMessages, activeFiles: files));
    }
  }

  Future<String> _mapErrorToMessage(Object e) async {
    final errorMessage = e.toString().toLowerCase();
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return 'Tidak ada koneksi internet. Mencoba menyambungkan kembali...';
    }
    if (errorMessage.contains('connection refused') ||
        errorMessage.contains('failed to connect')) {
      return 'Gagal terhubung ke server. Mencoba menyambungkan kembali...';
    } else {
      const serverErrorPrefix = 'error from server:';
      if (errorMessage.contains(serverErrorPrefix)) {
        return errorMessage.split(serverErrorPrefix).last.trim();
      }
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      ChatLoaded(
        messages: const [
          ChatMessage(text: 'loading', sender: MessageSender.system),
        ],
        activeFiles: const [],
      ),
    );

    try {
      final messages = await apiService.getChatMessages(event.chatId);
      final activeFiles = messages
          .where((m) => m.type == MessageType.attachment)
          .map(
            (m) => SelectedFile(
              fileName: m.originalFileName ?? m.text,
              fileBytes: Uint8List(0), // Bytes tidak diperlukan untuk display
            ),
          )
          .toList();

      emit(
        ChatLoaded(
          messages: messages,
          activeFiles: activeFiles,
          currentChatId: event.chatId,
        ),
      );
    } catch (e, s) {
      // Print error dan stack trace untuk debugging
      print('Error saat memuat riwayat chat: $e');
      print('Stack trace: $s');
      emit(
        ChatLoaded(
          messages: [
            ChatMessage(
              text: 'Error: Gagal memuat chat.',
              sender: MessageSender.system,
            ),
          ],
          activeFiles: [],
        ),
      );
    }
  }

  void _onClearChat(ClearChatEvent event, Emitter<ChatState> emit) {
    emit(ChatInitial());
  }
}
