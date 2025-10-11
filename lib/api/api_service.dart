import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:ai_cockpit_app/core/errors/exceptions.dart';
import 'package:ai_cockpit_app/data/models/ai_response.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:ai_cockpit_app/data/repositories/device_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final Dio _dio;
  final DeviceRepository deviceRepository;
  final Connectivity _connectivity;

  ApiService({
    required this.deviceRepository,
    required Connectivity connectivity,
  }) : _dio = Dio(
         BaseOptions(baseUrl: 'https://ai-cockpit-backend.vercel.app/api'),
       ),
       _connectivity = connectivity {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final connectivityResult = await _connectivity.checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.none)) {
            return handler.reject(
              DioException(requestOptions: options, error: NetworkException()),
            );
          }
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
      if (CancelToken.isCancel(e)) {
        rethrow;
      }

      if (e.response != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final responseData = e.response!.data as Map<String, dynamic>;
          final errorMessage =
              responseData['message'] ?? 'Gagal menganalisis dokumen.';
          throw AnalysisException(errorMessage);
        }
        throw ServerException(
          'Terjadi kesalahan pada server. Coba lagi nanti.',
        );
      }

      // Error jaringan atau lainnya
      if (e.error is NetworkException) {
        throw e.error as NetworkException;
      }
      throw ServerException('Gagal terhubung ke server. Periksa koneksi Anda.');
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
      if (e.response?.statusCode == 429) {
        throw GuestLimitExceededException();
      }

      if (e.response != null) {
        final errorMessage =
            (e.response!.data as Map<String, dynamic>)['message'] ??
            'Gagal mengirim pesan.';
        throw ServerException(errorMessage);
      }

      if (e.error is NetworkException) {
        throw e.error as NetworkException;
      }
      throw ServerException('Gagal mengirim pesan. Periksa koneksi Anda.');
    } catch (e) {
      developer.log('Error saat mengirim pertanyaan: $e', name: 'ApiService');
      throw ServerException('Terjadi kesalahan yang tidak diketahui.');
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

      if (e.response != null) {
        final errorMessage =
            (e.response!.data as Map<String, dynamic>)['message'] ??
            'Gagal memuat riwayat.';
        throw ServerException(errorMessage);
      }

      if (e.error is NetworkException) {
        throw e.error as NetworkException;
      }
      throw ServerException('Gagal memuat riwayat. Periksa koneksi Anda.');
    }
  }

  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    try {
      final response = await _dio.get('/chats/$chatId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            (e.response!.data as Map<String, dynamic>)['message'] ??
            'Gagal memuat detail chat.';
        throw ServerException(errorMessage);
      }

      if (e.error is NetworkException) {
        throw e.error as NetworkException;
      }
      throw ServerException('Gagal memuat detail chat. Silakan coba lagi.');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _dio.delete('/chats/$chatId');
      developer.log('Chat $chatId berhasil dihapus.', name: 'ApiService');
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            (e.response!.data as Map<String, dynamic>)['message'] ??
            'Gagal menghapus riwayat.';
        throw ServerException(errorMessage);
      }

      if (e.error is NetworkException) {
        throw e.error as NetworkException;
      }
      throw ServerException('Gagal menghapus riwayat. Coba lagi nanti.');
    }
  }

  Future<void> deleteAllChats() async {
    try {
      await _dio.delete('/chats');
      developer.log('Semua chat berhasil dihapus.', name: 'ApiService');
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            (e.response!.data as Map<String, dynamic>)['message'] ??
            'Gagal menghapus semua riwayat.';
        throw ServerException(errorMessage);
      }

      if (e.error is NetworkException) {
        throw e.error as NetworkException;
      }
      throw ServerException('Gagal menghapus semua riwayat. Coba lagi nanti.');
    }
  }
}
