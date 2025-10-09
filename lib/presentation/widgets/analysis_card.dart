import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalysisCard extends StatelessWidget {
  final String documentName;
  final String analysisText;

  const AnalysisCard({
    super.key,
    required this.documentName,
    required this.analysisText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2D2D2D),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analisis Jurnal: $documentName',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy_all_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: analysisText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hasil analisis disalin!')),
                    );
                  },
                  tooltip: 'Salin hasil analisis',
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.grey),
            MarkdownBody(
              data: analysisText,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white70,
                ),
                strong: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                listBullet: GoogleFonts.inter(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
