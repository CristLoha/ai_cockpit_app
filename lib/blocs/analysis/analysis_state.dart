part of 'analysis_bloc.dart';

enum AnalysisStatus { initial, loading, success, failure }

class AnalysisState extends Equatable {
  final AnalysisStatus status;

  final AnalysisResult? result;
  final String? errorMessage;

  const AnalysisState({
    this.status = AnalysisStatus.initial,
    this.result,
    this.errorMessage,
  });

  AnalysisState copyWith({
    AnalysisStatus? status,
    AnalysisResult? result,
    String? errorMessage,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage];
}
