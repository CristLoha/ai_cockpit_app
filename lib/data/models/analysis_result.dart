import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisResult {
  final String chatId;
  final String title;
  final List<String> authors;
  final String publication;
  final String summary;
  final List<String> keyPoints;
  final String methodology;
  final List<String> keywords;
  final List<String> references;
  final DateTime createdAt;
  final List<String> originalFileNames;

  AnalysisResult({
    required this.chatId,
    required this.title,
    required this.authors,
    required this.publication,
    required this.summary,
    required this.keyPoints,
    required this.methodology,
    required this.keywords,
    required this.references,
    required this.createdAt,
    required this.originalFileNames,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('analysis')
        ? json['analysis'] as Map<String, dynamic>
        : json;

    List<String> safeListParse(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }

      return [];
    }

    return AnalysisResult(
      chatId: (json['chatId'] ?? data['id'] ?? '').toString(),
      title: (data['title'] ?? 'Analisis Gabungan').toString(),
      authors: safeListParse(data['authors']),
      publication: (data['publication'] ?? '').toString(),
      summary: (data['summary'] ?? '').toString(),
      keyPoints: safeListParse(data['keyPoints']),
      methodology: (data['methodology'] ?? '').toString(),
      keywords: safeListParse(data['keywords']),
      references: safeListParse(data['references']),
      createdAt: _parseTimestamp(data['createdAt'] ?? json['createdAt']),
      originalFileNames: safeListParse(data['originalFileNames']),
    );
  }
}

DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return DateTime.now();
  if (timestamp is Timestamp) return timestamp.toDate();
  if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  }

  if (timestamp is Map && timestamp.containsKey('_seconds')) {
    final seconds = int.tryParse(timestamp['_seconds'].toString()) ?? 0;
    final nanoseconds = int.tryParse(timestamp['_nanoseconds'].toString()) ?? 0;
    return Timestamp(seconds, nanoseconds).toDate();
  }
  if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);

  return DateTime.now();
}
