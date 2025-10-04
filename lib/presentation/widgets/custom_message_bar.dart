import 'package:flutter/material.dart';

class CustomMessageBar extends StatefulWidget {
  final void Function(String) onSend;
  final VoidCallback onAttach;
  final List<String> selectedFileNames;
  final void Function(String) onRemoveFile;

  const CustomMessageBar({
    super.key,
    required this.onSend,
    required this.onAttach,
    this.selectedFileNames = const [],
    required this.onRemoveFile,
  });

  @override
  State<CustomMessageBar> createState() => _CustomMessageBarState();
}

class _CustomMessageBarState extends State<CustomMessageBar> {
  final TextEditingController _controller = TextEditingController();
  bool _canSendText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _canSendText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_canSendText || widget.selectedFileNames.isNotEmpty) {
      widget.onSend(_controller.text.trim());
      _controller.clear();
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
            onDeleted: () => widget.onRemoveFile(fileName),
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
    final bool hasFiles = widget.selectedFileNames.isNotEmpty;
    final bool canSend = _canSendText || widget.selectedFileNames.isNotEmpty;

    final String hintText = hasFiles
        ? 'Ketik pertanyaan tentang file...'
        : 'Lampirkan file untuk memulai...';
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      color: theme.appBarTheme.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.selectedFileNames.isNotEmpty) _buildFileChips(),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file_outlined),
                onPressed: widget.onAttach,
                color: Colors.white70,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: hintText,
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
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: _handleSend,
                color: canSend ? theme.colorScheme.primary : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
