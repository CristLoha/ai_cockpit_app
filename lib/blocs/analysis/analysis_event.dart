part of 'analysis_bloc.dart';

sealed class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object> get props => [];
}

class AnalysisDocumentRequested extends AnalysisEvent {}

class AdvancedAnalysisRequested extends AnalysisEvent {
  final String chatId;
  final String analysisType;

  const AdvancedAnalysisRequested({
    required this.chatId,
    required this.analysisType,
  });

  @override
  List<Object> get props => [chatId, analysisType];
}

class _AnalysisProgressUpdated extends AnalysisEvent {
  final double progress;

  const _AnalysisProgressUpdated(this.progress);

  @override
  List<Object> get props => [progress];
}
