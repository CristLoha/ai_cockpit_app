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
  // BARU: Tambahkan field untuk daftar file asli
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
    required this.originalFileNames, // Tambahkan di constructor
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('analysis')
        ? json['analysis'] as Map<String, dynamic>
        : json;

    return AnalysisResult(
      chatId: json['chatId'] ?? data['id'] ?? '',
      title: data['title'] ?? 'Analisis Gabungan',
      authors: List<String>.from(data['authors'] ?? []),
      publication: data['publication'] ?? '',
      summary: data['summary'] ?? '',
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      methodology: data['methodology'] ?? '',
      keywords: List<String>.from(data['keywords'] ?? []),
      references: List<String>.from(data['references'] ?? []),
      createdAt: _parseTimestamp(data['createdAt'] ?? json['createdAt']),
      // BARU: Parsing originalFileNames dari JSON
      originalFileNames: List<String>.from(data['originalFileNames'] ?? []),
    );
  }
}

DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return DateTime.now();
  if (timestamp is Timestamp) return timestamp.toDate();
  if (timestamp is String)
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  if (timestamp is Map && timestamp.containsKey('_seconds')) {
    return Timestamp(timestamp['_seconds'], timestamp['_nanoseconds']).toDate();
  }
  if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateTime.now();
}
