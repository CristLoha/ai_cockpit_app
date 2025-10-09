import 'dart:typed_data';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:ai_cockpit_app/services/docx_export_service.dart';
import 'package:ai_cockpit_app/services/pdf_export_service.dart';
import 'package:ai_cockpit_app/services/notification_service.dart'; // DITAMBAHKAN
import 'package:ai_cockpit_app/data/repositories/chat_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  late PdfExportService _pdfExportService;
  late DocxExportService _docxExportService;
  final NotificationService _notificationService; // DITAMBAHKAN

  ChatBloc({
    required ChatRepository chatRepository,
    required NotificationService notificationService, // DITAMBAHKAN
  }) : _chatRepository = chatRepository,
       _notificationService = notificationService, // DITAMBAHKAN
       super(const ChatState()) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<ClearChat>(_onClearChat);
    _pdfExportService = PdfExportService();
    _docxExportService = DocxExportService();
    on<AddSystemMessage>(_onAddSystemMessage);
    on<ExportAnalysis>(_onExportAnalysis);
  }

  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading, messages: []));
    try {
      final chatDetails = await _chatRepository.getChatMessages(event.chatId);
      final analysisData = AnalysisResult.fromJson(chatDetails['analysis']);
      final qaMessagesData = chatDetails['messages'] as List;
      final List<ChatMessage> qaMessages = qaMessagesData
          .map((msgJson) => ChatMessage.fromJson(msgJson))
          .toList();

      final initialAnalysisMessage = ChatMessage(
        text: 'Analisis awal dokumen.',
        sender: MessageSender.system,
        analysisResult: analysisData,

        timestamp: analysisData.createdAt,
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
      emit(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state.currentChatId == null) {
      emit(
        state.copyWith(
          status: ChatStatus.failure,
          errorMessage: 'Tidak ada sesi chat aktif',
        ),
      );
      return;
    }

    final currentMessages = List<ChatMessage>.from(state.messages);
    final userMessage = ChatMessage(
      text: event.question,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        status: ChatStatus.loading,
        messages: [...state.messages, userMessage],
      ),
    );

    try {
      final response = await _chatRepository.postQuestionToChat(
        chatId: state.currentChatId!,
        question: event.question,
      );

      final aiMessage = ChatMessage(
        text: response.answer,
        sender: MessageSender.ai,
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
      final errorMessageText = (e is Exception)
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();

      final errorMessage = ChatMessage(
        text: 'Error: $errorMessageText',
        sender: MessageSender.system,
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          status: ChatStatus.failure,
          // Hapus pesan user yang gagal terkirim dan tambahkan pesan error
          messages: [...currentMessages, errorMessage],
          errorMessage: errorMessageText,
        ),
      );
    }
  }

  void _onClearChat(ClearChat event, Emitter<ChatState> emit) {
    emit(const ChatState());
  }

  void _onAddSystemMessage(AddSystemMessage event, Emitter<ChatState> emit) {
    final analysisResult = event.message.analysisResult;
    if (analysisResult != null) {
      emit(
        state.copyWith(
          messages: [event.message],
          currentChatId: analysisResult.chatId,
        ),
      );
    } else {
      emit(state.copyWith(messages: [...state.messages, event.message]));
    }
  }

  Future<void> _onExportAnalysis(
    ExportAnalysis event,
    Emitter<ChatState> emit,
  ) async {
    if (state.currentChatId == null) {
      emit(
        state.copyWith(
          status: ChatStatus.exportFailure,
          errorMessage: 'Chat ID tidak ditemukan.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: ChatStatus.exporting));

    try {
      // Ambil data analisis dari state
      final analysisResult = state.messages
          .firstWhere((m) => m.analysisResult != null)
          .analysisResult;

      if (analysisResult == null) {
        throw Exception("Data analisis tidak ditemukan untuk diekspor.");
      }

      // Hasilkan file PDF atau DOCX berdasarkan format
      final Uint8List fileBytes;
      if (event.format == 'pdf') {
        fileBytes = await _pdfExportService.generateAnalysisPdf(analysisResult);
      } else if (event.format == 'docx') {
        fileBytes = (await _docxExportService.generateAnalysisDocx(
          analysisResult,
        ))!;
      } else {
        throw Exception('Format ekspor tidak didukung: ${event.format}');
      }

      bool hasPermission = false;

      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        // Android 13 (SDK 33) dan yang lebih baru tidak memerlukan izin untuk menyimpan ke direktori publik.
        if (deviceInfo.version.sdkInt >= 33) {
          hasPermission = true;
        } else {
          final status = await Permission.storage.request();
          hasPermission = status.isGranted;
        }
      } else {
        // Untuk iOS atau platform lain, asumsikan izin sudah ditangani atau tidak diperlukan.
        hasPermission = true;
      }

      if (!hasPermission) {
        emit(
          state.copyWith(
            status: ChatStatus.exportFailure,
            errorMessage: 'Izin penyimpanan diperlukan untuk mengekspor file.',
          ),
        );
        return;
      }

      final Directory? dir = await getDownloadsDirectory();
      if (dir == null) {
        throw Exception("Tidak dapat menemukan direktori downloads.");
      }

      final analysisTitle = analysisResult.title;
      // Ganti karakter yang tidak valid untuk nama file
      final safeTitle = analysisTitle.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
      final fileName = '$safeTitle.${event.format}';
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Coba tampilkan notifikasi, tapi jangan hentikan alur jika gagal.
      try {
        await _notificationService.showDownloadCompleteNotification(
          fileName: fileName,
          filePath: filePath,
        );
      } catch (e) {
        // Log error notifikasi, tapi jangan lempar exception ke UI
        // karena file sudah berhasil disimpan.
        print('Gagal menampilkan notifikasi: $e');
      }

      emit(state.copyWith(status: ChatStatus.exportSuccess));
    } catch (e) {
      final errorMessageText = (e is Exception)
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();

      emit(
        state.copyWith(
          status: ChatStatus.exportFailure,
          errorMessage: errorMessageText,
        ),
      );
    }
  }
}
