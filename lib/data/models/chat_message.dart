import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateTime.now();
  }
}
