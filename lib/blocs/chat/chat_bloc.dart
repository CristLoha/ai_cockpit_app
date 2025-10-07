import 'dart:async';
import 'dart:typed_data';
import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService apiService;
  ChatEvent? _lastEvent;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Logger _logger = Logger('ChatBloc');
  List<SelectedFile> _lastActiveFiles = [];
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

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        debugPrint('Error: ${record.error}');
        debugPrint('Stack trace:\n${record.stackTrace}');
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
    final filesToUse = event.files.isNotEmpty ? event.files : _lastActiveFiles;
    if (filesToUse.isEmpty) {
      emit(
        ChatLoaded(
          messages: [
            ...state.messages,
            ChatMessage(
              text: 'Error: Harap pilih file terlebih dahulu',
              sender: MessageSender.system,
            ),
          ],
          activeFiles: [],
        ),
      );
      return;
    }
    await _handleMessageSending(
      event.question,
      filesToUse,
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
                    text: doc['text'],
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

    _logger.info('Handling message sending');

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
        currentChatId: state.currentChatId,
      ),
    );

    try {
      Map<String, dynamic> apiResult;

      if (state.currentChatId != null) {
        _logger.info('Continuing existing chat: ${state.currentChatId}');
        apiResult = await apiService.continueChat(
          chatId: state.currentChatId!,
          question: question,
        );
      } else {
        _logger.info('Starting new chat with files');
        if (files.isEmpty) {
          throw Exception('Harap pilih file terlebih dahulu');
        }
        apiResult = await apiService.uploadDocumentAndGetAnswer(
          fileBytesList: files.map((f) => f.fileBytes).toList(),
          fileNameList: files.map((f) => f.fileName).toList(),
          question: question,
        );
      }

      final String answer =
          apiResult['answer'] as String? ?? 'Gagal mendapatkan jawaban.';
      final List<dynamic> processedDocs =
          (apiResult['processedDocuments'] as List<dynamic>?) ?? [];

      final correctAttachmentMessages = isNewFiles
          ? processedDocs.map((doc) => ChatMessage.fromJson(doc)).toList()
          : <ChatMessage>[];

      final finalMessages = List<ChatMessage>.from(baseMessages)
        ..addAll(correctAttachmentMessages)
        ..add(userMessage)
        ..add(ChatMessage(text: answer, sender: MessageSender.ai));

      emit(
        ChatLoaded(
          messages: finalMessages,
          activeFiles: files,
          currentChatId: apiResult['chatId'] as String? ?? state.currentChatId,
        ),
      );
      _lastEvent = null;
    } catch (e, stackTrace) {
      _logger.severe('Error sending message', e, stackTrace);
      String errorMessage;
      bool shouldRetry = false;
      Duration? retryDelay;

      if (e is RateLimitException) {
        errorMessage =
            'Batas penggunaan API tercapai. Mohon tunggu ${e.retryAfter.inSeconds} detik.';
        shouldRetry = true;
        retryDelay = e.retryAfter;
      } else {
        errorMessage = await _mapErrorToMessage(e);
      }

      final failureMessages = List<ChatMessage>.from(baseMessages)
        ..add(userMessage)
        ..add(
          ChatMessage(
            text: 'Error: $errorMessage',
            sender: MessageSender.system,
          ),
        );
      emit(
        ChatLoaded(
          messages: failureMessages,
          activeFiles: files,
          currentChatId: state.currentChatId,
        ),
      );

      if (shouldRetry && retryDelay != null) {
        await Future.delayed(retryDelay);
        add(_lastEvent as ChatEvent);
      }
    }
  }

  Future<String> _mapErrorToMessage(Object e) async {
    final errorMessage = e.toString().toLowerCase();
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return 'Tidak ada koneksi internet. Mencoba menyambungkan kembali...';
    }

    if (e is RateLimitException) {
      return 'Batas penggunaan API tercapai. Mohon tunggu ${e.retryAfter.inSeconds} detik.';
    }

    if (e is GuestLimitExceededException) {
      return 'Batas penggunaan tamu tercapai. Silakan Sign In untuk melanjutkan.';
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

      _lastActiveFiles = activeFiles;
      _logger.info('Chat history loaded successfully');

      emit(
        ChatLoaded(
          messages: messages,
          activeFiles: activeFiles,
          currentChatId: event.chatId,
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe('Error loading chat history', e, stackTrace);
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
    _lastActiveFiles = [];
    _logger.info('Chat cleared');
    emit(ChatInitial());
  }
}
