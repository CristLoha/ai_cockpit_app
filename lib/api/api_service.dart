import 'dart:typed_data';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:ai_cockpit_app/data/repositories/device_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateLimitException implements Exception {
  final Duration retryAfter;

  RateLimitException(this.retryAfter);
  @override
  String toString() =>
      'Rate limit exceeded. Please wait ${retryAfter.inSeconds} seconds.';
}

class GuestLimitExceededException implements Exception {
  @override
  String toString() =>
      'Batas penggunaan tamu tercapai. Silakan Sign In untuk melanjutkan.';
}

class ApiService {
  final String _baseUrl = 'http://10.0.2.2:3000/api';
  final Dio _dio = Dio();
  final DeviceRepository deviceRepository;

  ApiService({required this.deviceRepository});

  Future<Map<String, String>> _getHeaders() async {
    final deviceId = await deviceRepository.getDeviceId();
    final headers = <String, String>{'x-device-id': deviceId};

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Force refresh the token to ensure it's valid.
      final idToken = await user.getIdToken(true);
      headers['Authorization'] = 'Bearer $idToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> uploadDocumentAndGetAnswer({
    required List<Uint8List> fileBytesList,
    required List<String> fileNameList,
    required String question,
  }) async {
    try {
      // Add logging
      print('Starting file upload process');
      print('Number of files: ${fileBytesList.length}');
      print('File names: ${fileNameList.join(", ")}');

      if (fileBytesList.isEmpty || fileNameList.isEmpty) {
        throw Exception('No files selected');
      }

      final formData = FormData();

      // Add files to form data with better error handling
      for (var i = 0; i < fileBytesList.length; i++) {
        if (fileBytesList[i].isEmpty) {
          print('Warning: Empty file detected at index $i');
          continue;
        }

        formData.files.addAll([
          MapEntry(
            'documents',
            MultipartFile.fromBytes(
              fileBytesList[i],
              filename: fileNameList[i],
            ),
          ),
        ]);
      }

      formData.fields.add(MapEntry('userQuestion', question));

      final headers = await _getHeaders();
      print('Sending request to server...');
      final response = await _dio.post(
        '$_baseUrl/chat',
        data: formData,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 180), // 3 menit
          receiveTimeout: const Duration(seconds: 180), // 3 menit
        ),
        onSendProgress: (sent, total) {
          final percentage = (sent / total * 100).toStringAsFixed(2);
          print('Upload progress: $percentage%');
        },
      );

      print('Server response received');
      print('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio error occurred: ${e.type}');
      print('Error message: ${e.message}');
      print('Response data: ${e.response?.data}');

      if (e.response?.statusCode == 429) {
        final message = e.response?.data['message'] as String?;
        if (message?.contains('Batas penggunaan tamu tercapai') ?? false) {
          throw GuestLimitExceededException();
        }

        final retryAfter = e.response?.headers['retry-after']?[0];
        if (retryAfter != null) {
          throw RateLimitException(Duration(seconds: int.parse(retryAfter)));
        }
      }

      if (e.response?.statusCode == 403) {
        throw Exception(
          e.response?.data['message'] ?? 'Token tidak valid atau kedaluwarsa.',
        );
      }

      if (e.response?.statusCode == 400 &&
          e.response?.data['message']?.contains('Akses tamu ditolak')) {
        throw Exception('Akses tamu ditolak. Silakan coba lagi.');
      }

      throw Exception(
        'Error dari server: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<List<ChatHistoryItem>> getChatHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        '$_baseUrl/chats',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatHistoryItem.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat riwayat chat');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429 &&
          e.response?.data['message']?.contains('Batas penggunaan tamu')) {
        throw GuestLimitExceededException();
      }
      throw Exception(
        'Error server: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<Map<String, dynamic>> continueChat({
    required String chatId,
    required String question,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await _dio.post(
        '$_baseUrl/chat/$chatId/message',

        data: {'userQuestion': question},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to get answer from API: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429 &&
          e.response?.data['message']?.contains('Batas penggunaan tamu')) {
        throw GuestLimitExceededException();
      } else {
        throw Exception('Failed to connect to server: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<List<ChatMessage>> getChatMessages(String chatId) async {
    try {
      final headers = await _getHeaders();

      final response = await _dio.get(
        '$_baseUrl/chats/$chatId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat pesan chat');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
