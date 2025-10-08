import 'dart:typed_data';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart'; // FIX 1: Import yang hilang ditambahkan
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:ai_cockpit_app/data/repositories/chat_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState()) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<ClearChat>(_onClearChat);
    on<AddSystemMessage>(_onAddSystemMessage);
  }

  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading, messages: []));
    try {
      final chatDetails = await _chatRepository.getChatMessages(event.chatId);
      final analysisData = AnalysisResult.fromJson(chatDetails['analysis']);
      final qaMessagesData = chatDetails['messages'] as List;
      final List<ChatMessage> qaMessages = qaMessagesData.map((msgJson) => ChatMessage.fromJson(msgJson)).toList();

      final initialAnalysisMessage = ChatMessage(
        text: 'Analisis awal dokumen.',
        sender: MessageSender.system,
        analysisResult: analysisData,
        // FIX 2: Timestamp wajib diisi
        timestamp: analysisData.createdAt, // Menggunakan timestamp dari data analisis
      );

      final allMessages = [initialAnalysisMessage, ...qaMessages];

      emit(
        state.copyWith(
          status: ChatStatus.success,
          messages: allMessages,
          currentChatId: event.chatId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state.currentChatId == null) {
      emit(state.copyWith(status: ChatStatus.failure, errorMessage: 'Tidak ada sesi chat aktif'));
      return;
    }

    final userMessage = ChatMessage(
      text: event.question,
      sender: MessageSender.user,
      // FIX 3: Timestamp wajib diisi
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      status: ChatStatus.loading,
      messages: [...state.messages, userMessage],
    ));

    try {
      final response = await _chatRepository.postQuestionToChat(
        chatId: state.currentChatId!,
        question: event.question,
      );

      final aiMessage = ChatMessage(
        text: response.answer,
        sender: MessageSender.ai,
        // FIX 4: Timestamp wajib diisi
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          status: ChatStatus.success,
          messages: [...state.messages, aiMessage],
          errorMessage: null,
        ),
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Error: ${e.toString()}',
        sender: MessageSender.system,
        // FIX 5: Timestamp wajib diisi
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          status: ChatStatus.failure,
          messages: [...state.messages, errorMessage],
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onClearChat(ClearChat event, Emitter<ChatState> emit) {
    emit(const ChatState());
  }

  void _onAddSystemMessage(AddSystemMessage event, Emitter<ChatState> emit) {
    emit(state.copyWith(messages: [...state.messages, event.message]));
  }
}