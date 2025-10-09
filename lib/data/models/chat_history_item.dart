import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryItem {
  final String id;
  final String title;
  final DateTime createdAt;

  final List<String> authors;
  final String publication;
  final String summary;
  final List<String> keyPoints;
  final String methodology;

  ChatHistoryItem({
    required this.id,
    required this.title,
    required this.createdAt,

    required this.authors,
    required this.publication,
    required this.summary,
    required this.keyPoints,
    required this.methodology,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      id: json['id'] ?? 'invalid_id',
      title: json['title'] ?? 'Analisis Tanpa Judul',
      createdAt: _parseTimestamp(json['createdAt']),

      authors: List<String>.from(json['authors'] ?? []),
      publication: json['publication'] ?? '',
      summary: json['summary'] ?? '',
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
      methodology: json['methodology'] ?? '',
    );
  }
}

DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return DateTime.now();

  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }

  if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  }

  if (timestamp is Map && timestamp.containsKey('_seconds')) {
    return Timestamp(timestamp['_seconds'], timestamp['_nanoseconds']).toDate();
  }

  if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  return DateTime.now();
}
