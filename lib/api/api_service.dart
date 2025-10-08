import 'dart:typed_data'; // FIX 1: Import yang hilang
import 'package:dio/dio.dart'; // FIX 2: Import yang hilang
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:ai_cockpit_app/data/repositories/device_repository.dart';
import 'package:ai_cockpit_app/core/errors/exceptions.dart';
import 'package:ai_cockpit_app/data/models/ai_response.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';

class ApiService {
  final Dio _dio;
  final DeviceRepository deviceRepository;

  ApiService({required this.deviceRepository})
    : _dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000/api')) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final deviceId = await deviceRepository.getDeviceId();
          options.headers['x-device-id'] = deviceId;
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final idToken = await user.getIdToken(true);
            options.headers['Authorization'] = 'Bearer $idToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) => handler.next(response),
        onError: (DioException e, handler) => handler.next(e),
      ),
    );
  }

  Future<AnalysisResult> analyzeDocument({
    required List<Uint8List> fileBytesList,
    required List<String> fileNameList,
  }) async {
    try {
      final formData = FormData();
      for (var i = 0; i < fileBytesList.length; i++) {
        formData.files.add(
          MapEntry(
            'documents',
            MultipartFile.fromBytes(
              fileBytesList[i],
              filename: fileNameList[i],
            ),
          ),
        );
      }
      final response = await _dio.post(
        '/analyze',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 180),
          receiveTimeout: const Duration(seconds: 180),
        ),
      );
      return AnalysisResult.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error dari server: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<AIResponse> postQuestion({
    required String chatId,
    required String question,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/continue/$chatId',
        data: {'userQuestion': question},
      );
      return AIResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) throw GuestLimitExceededException();
      throw Exception('Gagal terhubung ke server: ${e.message}');
    }
  }

  Future<List<ChatHistoryItem>> getChatHistory() async {
    try {
      final response = await _dio.get('/chats');
      final List<dynamic> data = response.data;
      // FIX 3: Ganti `fromApiJson` menjadi `fromJson` standar
      return data
          .map((item) => ChatHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Gagal memuat riwayat chat: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    try {
      final response = await _dio.get('/chats/$chatId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat detail chat: $e');
    }
  }

  // DITAMBAHKAN KEMBALI: Method yang hilang
  Future<AnalysisResult> requestAdvancedAnalysis({
    required String chatId,
    required String analysisType,
    String? userInstruction,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/$chatId/analyze',
        data: {
          'analysisType': analysisType,
          if (userInstruction != null) 'userInstruction': userInstruction,
        },
      );
      return AnalysisResult.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error dari server: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }
}
