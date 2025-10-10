import 'dart:typed_data';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class DocxExportService {
  Future<Uint8List?> generateAnalysisDocx(AnalysisResult result) async {
    final data = await rootBundle.load(
      'assets/templates/analysis_template.docx',
    );
    final bytes = data.buffer.asUint8List();

    final docx = await DocxTemplate.fromBytes(bytes);

    final content = Content();

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

    final generatedBytes = await docx.generate(content);

    if (generatedBytes == null) {
      throw Exception("Gagal membuat file DOCX, hasil generate null.");
    }

    return Uint8List.fromList(generatedBytes);
  }
}
