import 'dart:typed_data';

import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/data/models/ai_response.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final ApiService _apiService;

  ChatRepository({required ApiService apiService}) : _apiService = apiService;

  Future<AnalysisResult> analyzeNewDocument({
    required String fileName,
    required Uint8List fileBytes,
    Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    return _apiService.analyzeDocument(
      fileBytes: fileBytes,
      fileName: fileName,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<AIResponse> postQuestionToChat({
    required String chatId,
    required String question,
  }) async {
    return _apiService.postQuestion(chatId: chatId, question: question);
  }

  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    return _apiService.getChatMessages(chatId);
  }

  Future<List<ChatHistoryItem>> getChatHistoryList() async {
    return _apiService.getChatHistoryList();
  }
}
