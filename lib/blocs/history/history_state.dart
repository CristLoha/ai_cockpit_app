part of 'history_cubit.dart';

abstract class HistoryState extends Equatable {
  final List<ChatHistoryItem> history;
  const HistoryState(this.history);

  @override
  List<Object> get props => [history];
}

class HistoryInitial extends HistoryState {
  HistoryInitial() : super([]);
}

class HistoryLoading extends HistoryState {
  const HistoryLoading(super.history);
}

class HistoryLoaded extends HistoryState {
  const HistoryLoaded(super.history);
}

class HistoryError extends HistoryState {
  final String message;

  @override
  List<Object> get props => [message, history];

  const HistoryError(this.message, super.history);
}
