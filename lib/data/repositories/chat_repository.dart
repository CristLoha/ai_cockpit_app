import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/data/models/ai_response.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';

class ChatRepository {
  final ApiService _apiService;

  ChatRepository({required ApiService apiService}) : _apiService = apiService;

  Future<AnalysisResult> analyzeNewDocument({
    required List<SelectedFile> files,
  }) async {
    final fileBytesList = files.map((f) => f.fileBytes).toList();
    final fileNameList = files.map((f) => f.fileName).toList();
    return _apiService.analyzeDocument(
      fileBytesList: fileBytesList,
      fileNameList: fileNameList,
    );
  }

  Future<AIResponse> postQuestionToChat({
    required String chatId,
    required String question,
  }) async {
    return _apiService.postQuestion(chatId: chatId, question: question);
  }

  // DITAMBAHKAN KEMBALI: Method ini dibutuhkan oleh AnalysisResultScreen
  Future<AnalysisResult> requestAdvancedAnalysis({
    required String chatId,
    required String analysisType,
  }) async {
    return _apiService.requestAdvancedAnalysis(
      chatId: chatId,
      analysisType: analysisType,
    );
  }

  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    return _apiService.getChatMessages(chatId);
  }

  // DITAMBAHKAN KEMBALI: Method ini dibutuhkan oleh HistoryCubit
  Future<List<ChatHistoryItem>> getChatHistoryList() async {
    return _apiService.getChatHistory();
  }
}
