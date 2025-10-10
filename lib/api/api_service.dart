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
    : _dio = Dio(
        BaseOptions(baseUrl: 'https://ai-cockpit-backend.vercel.app/api'),
      ) {
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

          developer.log(
            '--- REQUEST DIKIRIM KE SERVER ---',
            name: 'ApiService',
          );
          developer.log('URL: ${options.uri}', name: 'ApiService');
          developer.log('HEADERS: ${options.headers}', name: 'ApiService');
          developer.log(
            '------------------------------------',
            name: 'ApiService',
          );

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
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await _dio.post(
        '/analyze',
        data: formData,
        cancelToken: cancelToken,
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
      // Jika error adalah karena pembatalan, lempar kembali agar BLoC bisa menanganinya.
      if (CancelToken.isCancel(e)) {
        rethrow;
      }

      String finalErrorMessage = 'Terjadi kesalahan yang tidak diketahui.';

      if (e.response != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final responseData = e.response!.data as Map<String, dynamic>;
          finalErrorMessage =
              responseData['message'] ?? 'Gagal menganalisis dokumen.';
        } else {
          finalErrorMessage = e.response!.data.toString();
        }
      } else {
        // Jika tidak ada respons sama sekali (misal: masalah jaringan)
        finalErrorMessage = 'Gagal terhubung ke server. Periksa koneksi Anda.';
      }

      developer.log(
        'Error saat menganalisis dokumen: $finalErrorMessage',
        name: 'ApiService',
      );
      throw Exception(finalErrorMessage);
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

  Future<List<ChatHistoryItem>> getChatHistoryList() async {
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

  Future<void> deleteChat(String chatId) async {
    try {
      await _dio.delete('/chats/$chatId');
      developer.log('Chat $chatId berhasil dihapus.', name: 'ApiService');
    } on DioException catch (e) {
      developer.log(
        'Error saat menghapus chat: ${e.response?.data ?? e.message}',
        name: 'ApiService',
      );
      throw Exception('Gagal menghapus riwayat. Coba lagi nanti.');
    } catch (e) {
      developer.log(
        'Error tidak diketahui saat menghapus chat: $e',
        name: 'ApiService',
      );
      throw Exception('Terjadi kesalahan yang tidak diketahui.');
    }
  }

  Future<void> deleteAllChats() async {
    try {
      await _dio.delete('/chats');
      developer.log('Semua chat berhasil dihapus.', name: 'ApiService');
    } on DioException catch (e) {
      developer.log(
        'Error saat menghapus semua chat: ${e.response?.data ?? e.message}',
        name: 'ApiService',
      );
      throw Exception('Gagal menghapus semua riwayat. Coba lagi nanti.');
    } catch (e) {
      developer.log(
        'Error tidak diketahui saat menghapus semua chat: $e',
        name: 'ApiService',
      );
      throw Exception('Terjadi kesalahan yang tidak diketahui.');
    }
  }
}
