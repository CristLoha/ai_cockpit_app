import 'package:ai_cockpit_app/api/api_service.dart';
import 'package:ai_cockpit_app/data/models/chat_history_item.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final ApiService apiService;

  HistoryCubit({required this.apiService}) : super(HistoryInitial());

  Future<void> fetchHistory() async {
    if (state is HistoryLoading) return;

    emit(HistoryLoading());
    try {
      final historyList = await apiService.getChatHistory();
      emit(HistoryLoaded(historyList));
    } catch (e, stackTrace) {
      print('==================== HISTORY CUBIT ERROR ====================');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('=============================================================');

      emit(HistoryError(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}
