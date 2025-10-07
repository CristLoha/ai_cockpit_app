import 'package:flutter/material.dart';

class FileAttachmentBubble extends StatelessWidget {
  final String title;
  final String originalFileName;

  const FileAttachmentBubble({
    super.key,
    required this.title,
    required this.originalFileName,
  });

  IconData _getFileIcon() {
    if (originalFileName.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (originalFileName.toLowerCase().endsWith('.docx')) {
      return Icons.article_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getIconColor() {
    if (originalFileName.toLowerCase().endsWith('.pdf')) {
      return Colors.red.shade400;
    } else if (originalFileName.toLowerCase().endsWith('.docx')) {
      return Colors.blue.shade400;
    }
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getFileIcon(), color: _getIconColor()),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
