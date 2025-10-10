import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final ApiService apiService;

  HistoryCubit({required this.apiService}) : super(HistoryInitial());

  Future<void> fetchHistory() async {
    // Ambil data lama jika ada, untuk ditampilkan saat loading
    final currentHistory = state.history;
    emit(HistoryLoading(currentHistory));
    try {
      final history = await apiService.getChatHistoryList();
      // Urutkan dari yang terbaru
      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(HistoryLoaded(history));
    } catch (e) {
      emit(
        HistoryError(
          e.toString().replaceFirst('Exception: ', ''),
          currentHistory,
        ),
      );
    }
  }

  Future<void> deleteChat(String chatId) async {
    final currentState = state;
    if (currentState is! HistoryLoaded && currentState is! HistoryError) return;

    // Optimistic UI update: hapus item dari list sebelum request API
    final currentHistory = List<ChatHistoryItem>.from(currentState.history);
    final itemIndex = currentHistory.indexWhere((item) => item.id == chatId);
    if (itemIndex == -1) return;

    currentHistory.removeAt(itemIndex);
    emit(HistoryLoaded(currentHistory)); // Tampilkan list yang sudah diupdate

    try {
      await apiService.deleteChat(chatId);
      // Jika berhasil, state sudah benar. Tidak perlu fetch ulang.
      developer.log('Successfully deleted chat $chatId from UI and API');
    } catch (e) {
      // Jika gagal, kembalikan state seperti semula dan tampilkan error
      developer.log('Failed to delete chat $chatId: $e');
      // Panggil fetchHistory untuk sinkronisasi ulang dengan server
      fetchHistory();
    }
  }

  Future<void> deleteAllChats() async {
    final currentState = state;
    if (currentState is! HistoryLoaded && currentState is! HistoryError) return;

    final previousHistory = List<ChatHistoryItem>.from(currentState.history);
    emit(HistoryLoaded(const [])); // Optimistic UI: langsung kosongkan list

    try {
      await apiService.deleteAllChats();
      developer.log('Successfully deleted all chats from UI and API');
    } catch (e) {
      developer.log('Failed to delete all chats: $e');
      // Jika gagal, kembalikan state ke list sebelumnya dan tampilkan error
      emit(
        HistoryError(
          e.toString().replaceFirst('Exception: ', ''),
          previousHistory,
        ),
      );
    }
  }

  void clearHistory() {
    emit(HistoryLoaded(const []));
  }
}
