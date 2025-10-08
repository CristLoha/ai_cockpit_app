import 'package:cloud_firestore/cloud_firestore.dart';

class ChatHistoryItem {
  final String id;
  final String title;
  final DateTime createdAt;
  // BARU: Tambahkan semua properti lain dari analisis agar bisa ditampilkan
  final List<String> authors;
  final String publication;
  final String summary;
  final List<String> keyPoints;
  final String methodology;
  // Tambahkan field lain jika ada, seperti 'keywords' atau 'references'

  ChatHistoryItem({
    required this.id,
    required this.title,
    required this.createdAt,
    // Inisialisasi properti baru
    required this.authors,
    required this.publication,
    required this.summary,
    required this.keyPoints,
    required this.methodology,
  });

  // DIUBAH TOTAL: Sekarang hanya ada satu factory `fromJson` yang kuat.
  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      id: json['id'] ?? 'invalid_id',
      title: json['title'] ?? 'Analisis Tanpa Judul',
      createdAt: _parseTimestamp(json['createdAt']),
      // Ambil juga data analisis lainnya
      authors: List<String>.from(json['authors'] ?? []),
      publication: json['publication'] ?? '',
      summary: json['summary'] ?? '',
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
      methodology: json['methodology'] ?? '',
    );
  }
}

// Helper untuk parsing timestamp yang fleksibel, bisa ditaruh di sini atau di file terpisah
DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return DateTime.now();
  // Jika dari Firestore langsung (tipe data Timestamp)
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  // Jika dari JSON API (tipe data String)
  if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  }
  // Jika dari JSON API (tipe data Map dari Firestore JS, contoh: {_seconds: ..., _nanoseconds: ...})
  if (timestamp is Map && timestamp.containsKey('_seconds')) {
    return Timestamp(timestamp['_seconds'], timestamp['_nanoseconds']).toDate();
  }
  // Jika dari JSON (tipe data int, yaitu milidetik)
  if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  // Fallback jika format tidak dikenali
  return DateTime.now();
}
