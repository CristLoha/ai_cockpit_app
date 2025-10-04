import 'dart:typed_data';
import 'package:dio/dio.dart';

class ApiService {
  final String _baseUrl = 'http://10.0.2.2:3000/api';
  final Dio _dio = Dio();

  Future<String> uploadDocumentAndGetAnswer({
    required List<Uint8List> fileBytesList,
    required List<String> fileNameList,
    required String question,
  }) async {
    try {
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
        onSendProgress: (sent, total) {
          if (total != -1) {
            print(
              'Upload progress: ${(sent / total * 100).toStringAsFixed(2)}%',
            );
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data['answer'];
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
}
