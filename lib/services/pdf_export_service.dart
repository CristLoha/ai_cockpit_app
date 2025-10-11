import 'dart:typed_data';

import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  Future<Uint8List> generateAnalysisPdf(AnalysisResult result) async {
    final pdf = pw.Document();

    final spaceGroteskBold = await PdfGoogleFonts.spaceGroteskBold();
    final interRegular = await PdfGoogleFonts.interRegular();
    final interBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              result.title,
              style: pw.TextStyle(font: spaceGroteskBold, fontSize: 24),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Penulis: ${result.authors.join(", ")}',
                  style: pw.TextStyle(
                    font: interRegular,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.Text(
                DateFormat('d MMMM yyyy').format(result.createdAt),
                style: pw.TextStyle(
                  font: interRegular,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
          if (result.publication.isNotEmpty)
            pw.Text(
              'Publikasi: ${result.publication}',
              style: pw.TextStyle(
                font: interRegular,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          pw.SizedBox(height: 24),

          _buildSectionTitle('Ringkasan Dokumen', interBold),
          pw.Paragraph(
            text: result.summary,
            style: pw.TextStyle(font: interRegular, lineSpacing: 2),
          ),
          pw.SizedBox(height: 24),

          if (result.keywords.isNotEmpty) ...[
            _buildSectionTitle('Kata Kunci', interBold),
            pw.Wrap(
              spacing: 8,
              runSpacing: 4,
              children: result.keywords
                  .map(
                    (k) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        k,
                        style: pw.TextStyle(font: interRegular),
                      ),
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 24),
          ],

          if (result.keyPoints.isNotEmpty) ...[
            _buildSectionTitle('Poin Kunci', interBold),
            ...result.keyPoints.map(
              (point) => pw.Bullet(
                text: point,
                style: pw.TextStyle(font: interRegular, lineSpacing: 2),
                bulletMargin: const pw.EdgeInsets.only(right: 8, top: 4),
              ),
            ),
            pw.SizedBox(height: 24),
          ],

          if (result.methodology.isNotEmpty) ...[
            _buildSectionTitle('Metodologi', interBold),
            pw.Paragraph(
              text: result.methodology,
              style: pw.TextStyle(font: interRegular, lineSpacing: 2),
            ),
            pw.SizedBox(height: 24),
          ],

          if (result.references.isNotEmpty) ...[
            _buildSectionTitle('Referensi Utama', interBold),
            ...result.references.map(
              (ref) => pw.Paragraph(
                text: ref,
                style: pw.TextStyle(font: interRegular, lineSpacing: 2),
                margin: const pw.EdgeInsets.only(bottom: 4),
              ),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12.0, top: 12.0),
      child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 16)),
    );
  }
}
