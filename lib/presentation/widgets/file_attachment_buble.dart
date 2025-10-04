import 'package:flutter/material.dart';

class FileAttachmentBubble extends StatelessWidget {
  final String fileName;
  const FileAttachmentBubble({super.key, required this.fileName});

  IconData _getFileIcon() {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (fileName.toLowerCase().endsWith('.docx')) {
      return Icons.article_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getFileIcon(), color: Colors.white70),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
