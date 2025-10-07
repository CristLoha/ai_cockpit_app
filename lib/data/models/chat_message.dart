import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageType { text, attachment }

enum MessageSender { user, ai, system }

class ChatMessage extends Equatable {
  final String text;
  final MessageSender sender;
  final MessageType type;
  final String? originalFileName;
  final DateTime? timesStamp;

  const ChatMessage({
    required this.text,
    required this.sender,
    this.type = MessageType.text,
    this.originalFileName,
    this.timesStamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    MessageSender sender;
    switch (json['sender']) {
      case 'ai':
        sender = MessageSender.ai;
        break;
      case 'user':
        sender = MessageSender.user;
        break;
      default:
        sender = MessageSender.system;
    }

    final timestampData = json['timestamp'];
    DateTime? timestamp;
    if (timestampData is Timestamp) {
      timestamp = timestampData.toDate();
    } else if (timestampData is Map) {
      timestamp = Timestamp(
        timestampData['_seconds'],
        timestampData['_nanoseconds'],
      ).toDate();
    } else if (timestampData != null) {
      print('Invalid format for timestamp: $timestampData');
    }

    return ChatMessage(
      text: json['text'],
      sender: sender,
      type: json['type'] == 'attachment'
          ? MessageType.attachment
          : MessageType.text,
      originalFileName: json['originalFileName'],
      timesStamp: timestamp,
    );
  }

  @override
  List<Object?> get props => [text, sender, type, originalFileName];
}
