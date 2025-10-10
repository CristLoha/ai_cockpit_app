import 'package:ai_cockpit_app/blocs/chat/chat_bloc.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:ai_cockpit_app/data/models/chat_message.dart';
import 'package:ai_cockpit_app/presentation/screens/chat_screen.dart';
import 'package:ai_cockpit_app/presentation/widgets/analysis_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult? result;
  final String chatId;

  const AnalysisResultScreen({super.key, this.result, required this.chatId});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  @override
  void initState() {
    super.initState();
    // Jika widget.result disediakan, itu berarti analisis baru saja selesai.
    // Dalam kasus ini, kita menambahkan pesan analisis awal ke ChatBloc.
    // Jika tidak (navigasi dari riwayat), ChatBloc seharusnya sudah
    // diinstruksikan untuk memuat chat oleh HistoryDrawer.
    if (widget.result != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final initialAnalysisMessage = ChatMessage(
          text: 'Analisis awal dokumen.',
          sender: MessageSender.system,
          analysisResult: widget.result,
          timestamp: widget.result!.createdAt,
        );
        context.read<ChatBloc>().add(AddSystemMessage(initialAnalysisMessage));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          'Dasbor Analisis',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2D2D2D),
        actions: [_buildExportButton(context), const SizedBox(width: 8)],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ChatBloc, ChatState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                (current.status == ChatStatus.exporting ||
                    current.status == ChatStatus.exportSuccess ||
                    current.status == ChatStatus.exportFailure),
            listener: (context, state) {
              if (state.status == ChatStatus.exporting) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Mengekspor hasil analisis...'),
                    ),
                  );
              } else if (state.status == ChatStatus.exportSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('File berhasil diekspor dan disimpan.'),
                      backgroundColor: Colors.green,
                    ),
                  );
              } else if (state.status == ChatStatus.exportFailure) {
                final errorMessage =
                    state.errorMessage ??
                    'Terjadi kesalahan yang tidak diketahui.';
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengekspor: $errorMessage'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
              }
            },
          ),
        ],
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, chatState) {
            if ((chatState.status == ChatStatus.loading ||
                    chatState.status == ChatStatus.initial) &&
                chatState.messages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final analysisMessage = chatState.messages.firstWhere(
              (msg) => msg.analysisResult != null,
              orElse: () => ChatMessage(
                text: 'fallback',
                sender: MessageSender.system,
                timestamp: DateTime.now(),
              ),
            );
            final displayData = analysisMessage.analysisResult;

            if (displayData == null) {
              return const Center(
                child: Text(
                  "Data analisis tidak ditemukan.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayData.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (displayData.authors.isNotEmpty) ...[
                    _buildMetaInfo(
                      Icons.people_alt_outlined,
                      displayData.authors.join(', '),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (displayData.publication.isNotEmpty) ...[
                    _buildMetaInfo(
                      Icons.library_books_outlined,
                      displayData.publication,
                    ),
                  ],
                  const SizedBox(height: 24),

                  _buildSectionTitle("Ringkasan Dokumen"),
                  AnalysisCard(
                    documentName: "",
                    analysisText: displayData.summary,
                  ),
                  const SizedBox(height: 24),

                  if (displayData.keywords.isNotEmpty) ...[
                    _buildSectionTitle("Kata Kunci"),
                    _buildKeywords(displayData.keywords),
                    const SizedBox(height: 24),
                  ],

                  if (displayData.keyPoints.isNotEmpty) ...[
                    _buildSectionTitle("Poin Kunci"),
                    _buildKeyPoints(displayData.keyPoints),
                    const SizedBox(height: 24),
                  ],

                  if (displayData.methodology.isNotEmpty) ...[
                    _buildSectionTitle("Metodologi"),
                    Text(
                      displayData.methodology,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (displayData.references.isNotEmpty) ...[
                    _buildSectionTitle("Referensi Utama"),
                    _buildReferences(displayData.references),
                    const SizedBox(height: 32),
                  ],

                  Center(child: _buildQnAButton(context, widget.chatId)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String format) {
        context.read<ChatBloc>().add(ExportAnalysis(format: format));
      },
      icon: const Icon(Icons.ios_share),
      tooltip: 'Ekspor Analisis',
      color: const Color(0xFF2D2D2D),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: Colors.red.shade300),
              const SizedBox(width: 12),
              const Text('Ekspor sebagai PDF'),
            ],
          ),
        ),
        // const PopupMenuDivider(),
        // PopupMenuItem<String>(
        //   value: 'docx',
        //   child: Row(
        //     children: [
        //       Icon(Icons.description_outlined, color: Colors.blue.shade300),
        //       const SizedBox(width: 12),
        //       const Text('Ekspor sebagai DOCX'),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetaInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywords(List<String> keywords) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: keywords
          .map(
            (keyword) => Chip(
              label: Text(
                keyword,
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              backgroundColor: Colors.deepPurple.withAlpha(
                51,
              ), // Already using withAlpha
              side: BorderSide(
                color: Colors.deepPurple.withAlpha(128),
              ), // Already using withAlpha
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildKeyPoints(List<String> points) {
    return Column(
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, right: 8.0),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildReferences(List<String> references) {
    return Column(
      children: references
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}. ',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      height: 1.6,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildQnAButton(BuildContext context, String chatId) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.question_answer_outlined, color: Colors.white),
        label: Text(
          'Mulai Sesi Tanya Jawab',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ChatBloc>(),
                child: ChatScreen(chatId: chatId),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
