import 'package:ai_cockpit_app/data/models/analysis_result.dart'; // FIX 1: Tambahkan import ini
import 'package:cloud_firestore/cloud_firestore.dart'; // Import untuk handle Timestamp
import 'package:equatable/equatable.dart';
enum MessageSender { user, ai, system }
enum MessageType { text, attachment }

class ChatMessage extends Equatable {
  final String text;
  final MessageSender sender;
  final MessageType type;
  final String? originalFileName;
  final AnalysisResult? analysisResult;
  final DateTime timestamp;

  // Tambahkan 'const' di sini
  const ChatMessage({
    required this.text,
    required this.sender,
    this.type = MessageType.text,
    this.originalFileName,
    this.analysisResult,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, sender, type, timestamp, analysisResult];

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      sender: _senderFromString(json['sender']),
      type: _typeFromString(json['type']),
      originalFileName: json['originalFileName'],
      analysisResult: json['analysisResult'] != null
          ? AnalysisResult.fromJson(json['analysisResult'])
          : null,
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }
  // Helper untuk konversi String ke Enum dengan aman
  static MessageSender _senderFromString(String? sender) {
    switch (sender) {
      case 'user':
        return MessageSender.user;
      case 'ai':
        return MessageSender.ai;
      default:
        return MessageSender.system;
    }
  }

  static MessageType _typeFromString(String? type) {
    return type == 'attachment' ? MessageType.attachment : MessageType.text;
  }

  // Helper untuk parsing timestamp yang fleksibel
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    // Jika dari Firestore langsung (tipe data Timestamp)
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    // Jika dari JSON (tipe data String)
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    // Jika dari JSON (tipe data int, yaitu milidetik)
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    // Fallback jika format tidak dikenali
    return DateTime.now();
  }
}
