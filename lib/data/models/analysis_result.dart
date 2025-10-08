// lib/data/models/analysis_result.dart
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
  });

  // DISEDERHANAKAN & DIPERBAIKI: Factory ini sekarang benar
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // Cek jika ini adalah respons dari /api/analyze yang punya nested 'analysis'
    final data = json.containsKey('analysis')
        ? json['analysis'] as Map<String, dynamic>
        : json;

    return AnalysisResult(
      // Jika dari /api/analyze, chatId ada di level atas. Jika dari history, ada di dalam sebagai 'id'.
      chatId: json['chatId'] ?? data['id'] ?? '',
      title: data['title'] ?? 'Judul Tidak Ditemukan',
      authors: List<String>.from(data['authors'] ?? []),
      publication: data['publication'] ?? '',
      summary: data['summary'] ?? '',
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      methodology: data['methodology'] ?? '',
      keywords: List<String>.from(data['keywords'] ?? []),
      references: List<String>.from(data['references'] ?? []),
      createdAt: _parseTimestamp(data['createdAt'] ?? json['createdAt']),
    );
  }
}

// Helper untuk parsing timestamp
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
