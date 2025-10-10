import 'package:ai_cockpit_app/blocs/auth/auth_cubit.dart';
import 'package:ai_cockpit_app/blocs/chat/chat_bloc.dart';
import 'package:ai_cockpit_app/blocs/history/history_cubit.dart';
import 'package:ai_cockpit_app/presentation/screens/analysis_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class HistoryDrawer extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback onNewChat;

  const HistoryDrawer({
    super.key,
    required this.isAuthenticated,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),

      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is Authenticated) {
                  return _buildHistoryList();
                }
                return _buildSignInPrompt(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 140,
      child: DrawerHeader(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Analisis',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAuthenticated) _buildDeleteAllButton(context),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Sesi analisis Anda sebelumnya.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAllButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
      tooltip: 'Hapus Semua Riwayat',
      onPressed: () => _showDeleteConfirmationDialog(
        context,
        title: 'Hapus Semua Riwayat?',
        content:
            'Tindakan ini tidak dapat diurungkan. Semua riwayat analisis Anda akan dihapus secara permanen.',
        onConfirm: () {
          context.read<HistoryCubit>().deleteAllChats();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    return BlocConsumer<HistoryCubit, HistoryState>(
      listener: (context, state) {
        if (state is HistoryError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
        }
      },
      builder: (context, historyState) {
        if (historyState is HistoryLoading && historyState.history.isEmpty) {
          return _buildShimmerLoading();
        }
        if (historyState is HistoryLoaded ||
            (historyState is HistoryLoading &&
                historyState.history.isNotEmpty)) {
          final historyList = historyState.history;
          if (historyList.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              return _buildHistoryItem(context, item);
            },
          );
        }
        if (historyState is HistoryError) {
          // Tampilkan empty state jika error terjadi tapi ada data lama
          if (historyState.history.isEmpty) {
            return _buildErrorState(context, historyState.message);
          }
        }
        return _buildEmptyState(); // Fallback
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, ChatHistoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToChat(context, item.id),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat.yMMMd().add_jm().format(item.createdAt),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.grey,
                    size: 22,
                  ),
                  onPressed: () => _showDeleteConfirmationDialog(
                    context,
                    title: 'Hapus Riwayat?',
                    content:
                        'Anda yakin ingin menghapus riwayat analisis "${item.title}"?',
                    onConfirm: () {
                      context.read<HistoryCubit>().deleteChat(item.id);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, String chatId) async {
    final chatBloc = context.read<ChatBloc>();
    final navigator = Navigator.of(context);

    // Tutup drawer terlebih dahulu
    navigator.pop();
    // Beri jeda agar transisi drawer selesai
    await Future.delayed(const Duration(milliseconds: 50));

    chatBloc.add(LoadChat(chatId));

    navigator.push(
      MaterialPageRoute(builder: (_) => AnalysisResultScreen(chatId: chatId)),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            content,
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: onConfirm,
              child: Text(
                'Hapus',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 48,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<HistoryCubit>().fetchHistory(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              'Masuk untuk melihat riwayat',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AuthCubit>().signInWithGoogle();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.login),
              label: const Text('Masuk dengan Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF2A2A2A),
        highlightColor: const Color(0xFF3D3D3D),
        child: ListView.builder(
          itemCount: 8,
          itemBuilder: (_, __) => Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(height: 70),
          ),
        ),
      ),
    );
  }
}
