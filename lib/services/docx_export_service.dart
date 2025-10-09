import 'dart:typed_data';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class DocxExportService {
  Future<Uint8List?> generateAnalysisDocx(AnalysisResult result) async {
    // 1. Muat file template dari assets
    final data = await rootBundle.load(
      'assets/templates/analysis_template.docx',
    );
    final bytes = data.buffer.asUint8List();

    // 2. Buat template dari byte
    final docx = await DocxTemplate.fromBytes(bytes);

    // 3. Siapkan konten untuk mengisi placeholder
    final content = Content();

    // Teks biasa
    content.add(TextContent("title", result.title));
    content.add(TextContent("authors", result.authors.join(', ')));
    content.add(TextContent("publication", result.publication));
    content.add(
      TextContent(
        "createdAt",
        DateFormat('d MMMM yyyy').format(result.createdAt),
      ),
    );
    content.add(TextContent("summary", result.summary));
    content.add(TextContent("methodology", result.methodology));

    // List/Loop
    // DIUBAH: Gunakan PlainContent untuk list string sederhana agar cocok dengan template {{.}}
    content.add(
      ListContent("keywords", [
        for (final k in result.keywords) PlainContent(k),
      ]),
    );
    content.add(
      ListContent("keyPoints", [
        for (final p in result.keyPoints) PlainContent("•\t$p"),
      ]),
    );
    content.add(
      ListContent("references", [
        for (final r in result.references) PlainContent("•\t$r"),
      ]),
    );

    // 4. Hasilkan dokumen final
    final generatedBytes = await docx.generate(content);

    if (generatedBytes == null) {
      throw Exception("Gagal membuat file DOCX, hasil generate null.");
    }

    return Uint8List.fromList(generatedBytes);
  }
}
