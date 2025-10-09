import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
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
            final idToken = await user.getIdToken();
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
    required Uint8List fileBytes,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.post(
        '/analyze',
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0) {
            double progress = sent / total;
            onProgress?.call(progress);
          }
        },
        options: Options(
          sendTimeout: const Duration(seconds: 180),
          receiveTimeout: const Duration(seconds: 180),
        ),
      );
      return AnalysisResult.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        developer.log(
          'Authentication error during analysis: ${e.response?.data ?? e.message}',
          name: 'ApiService',
        );
        throw Exception(
          'Akses ditolak. Silakan Sign In untuk menganalisis dokumen.',
        );
      }

      developer.log(
        'Error saat menganalisis dokumen: ${e.response?.data ?? e.message}',
        name: 'ApiService',
      );
      throw Exception('Gagal menganalisis dokumen. Silakan coba lagi.');
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
      developer.log(
        'Error saat mengirim pertanyaan: ${e.response?.data ?? e.message}',
        name: 'ApiService',
      );

      throw Exception('Gagal mengirim pesan. Periksa koneksi Anda.');
    }
  }

  Future<List<ChatHistoryItem>> getChatHistory() async {
    try {
      final response = await _dio.get('/chats');
      final List<dynamic> data = response.data;

      return data
          .map((item) => ChatHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        developer.log(
          'Gagal memuat riwayat: Pengguna belum login.',
          name: 'ApiService',
        );
        return [];
      }

      developer.log(
        'Error saat memuat riwayat: ${e.response?.data ?? e.message}',
        name: 'ApiService',
      );
      throw Exception('Gagal memuat riwayat. Periksa koneksi Anda.');
    }
  }

  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    try {
      final response = await _dio.get('/chats/$chatId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Error saat memuat detail chat: $e', name: 'ApiService');
      throw Exception('Gagal memuat detail chat. Silakan coba lagi.');
    }
  }
}
