import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryItem extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;

  const ChatHistoryItem({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    final createdAtData = json['createdAt'];
    DateTime createdAt;
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is Map) {
      createdAt = Timestamp(
        createdAtData['_seconds'],
        createdAtData['_nanoseconds'],
      ).toDate();
    } else {
      throw Exception('Invalid format for createdAt');
    }
    return ChatHistoryItem(
      id: json['id'],
      title: json['title'],
      createdAt: createdAt,
    );
  }

  @override
  List<Object> get props => [id];
}
