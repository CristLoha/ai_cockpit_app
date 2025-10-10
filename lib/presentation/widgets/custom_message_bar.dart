import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomMessageBar extends StatefulWidget {
  final void Function(String) onSend;

  final VoidCallback? onAttach;
  final List<String> selectedFileNames;

  final void Function(String)? onRemoveFile;

  final String hintText;

  const CustomMessageBar({
    super.key,
    required this.onSend,
    this.onAttach,
    this.selectedFileNames = const [],
    this.onRemoveFile,
    required this.hintText,
  });

  @override
  State<CustomMessageBar> createState() => _CustomMessageBarState();
}

class _CustomMessageBarState extends State<CustomMessageBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.trim().isNotEmpty ||
        widget.selectedFileNames.isNotEmpty) {
      widget.onSend(_controller.text.trim());
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildFileChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.selectedFileNames.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fileName = widget.selectedFileNames[index];
          return Chip(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            label: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4,
              ),
              child: Text(
                fileName,
                style: const TextStyle(color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            avatar: Icon(
              fileName.toLowerCase().endsWith('.pdf')
                  ? Icons.picture_as_pdf_rounded
                  : Icons.article_rounded,
              color: Colors.white70,
              size: 18,
            ),
            onDeleted: widget.onRemoveFile != null
                ? () => widget.onRemoveFile!(fileName)
                : null,
            deleteIcon: const Icon(Icons.close, size: 18),
            padding: const EdgeInsets.all(4),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;
        final hasFiles = widget.selectedFileNames.isNotEmpty;
        final canSend = hasText || hasFiles;

        return Container(
          padding: EdgeInsets.fromLTRB(
            4,
            8,
            4,
            MediaQuery.of(context).padding.bottom + 4,
          ),
          color: theme.appBarTheme.backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasFiles) _buildFileChips(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onAttach != null)
                    IconButton(
                      icon: const Icon(Icons.attach_file_outlined),
                      onPressed: widget.onAttach,
                      color: Colors.white70,
                      tooltip: 'Lampirkan File',
                    ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(color: Colors.white),
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: theme.colorScheme.secondary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: canSend ? (_) => _handleSend() : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),

                    onPressed: canSend ? _handleSend : null,
                    color: canSend ? theme.colorScheme.primary : Colors.grey,
                    tooltip: 'Kirim',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
