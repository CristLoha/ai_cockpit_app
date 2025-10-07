import 'dart:typed_data';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:ai_cockpit_app/data/repositories/device_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final String _baseUrl = 'http://10.0.2.2:3000/api';
  final Dio _dio = Dio();
  final DeviceRepository deviceRepository;
  String? idToken;
  final user = FirebaseAuth.instance.currentUser;

  ApiService({required this.deviceRepository});

  Future<Map<String, dynamic>> uploadDocumentAndGetAnswer({
    required List<Uint8List> fileBytesList,
    required List<String> fileNameList,
    required String question,
  }) async {
    try {
      if (user != null) {
        idToken = await user!.getIdToken(true);
      }
      final deviceId = await deviceRepository.getDeviceId();

      final headers = <String, String>{'x-device-id': deviceId};

      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }

      final formData = FormData();

      formData.fields.add(MapEntry('userQuestion', question));

      for (int i = 0; i < fileBytesList.length; i++) {
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
        '$_baseUrl/chat',

        data: formData,
        options: Options(headers: headers),
        onSendProgress: (sent, total) {
          if (total != -1) {
            print(
              'Upload progress: ${(sent / total * 100).toStringAsFixed(2)}%',
            );
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to get answer from API: ${response.data['message']}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Error from server: ${e.response?.data['message'] ?? e.message}',
        );
      } else {
        throw Exception('Failed to connect to server: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<List<ChatHistoryItem>> getChatHistory() async {
    try {
      if (user == null) {
        return [];
      }
      final idToken = await user!.getIdToken(true);
      final response = await _dio.get(
        '$_baseUrl/chats',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatHistoryItem.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat riwayat chat');
      }
    } on DioException catch (e) {
      throw Exception(
        'Error server: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<List<ChatMessage>> getChatMessages(String chatId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final idToken = await user.getIdToken(true);

      final response = await _dio.get(
        '$_baseUrl/chats/$chatId',
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
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
