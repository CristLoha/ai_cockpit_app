part of 'analysis_bloc.dart';

enum AnalysisStatus { initial, loading, success, failure }

class AnalysisState extends Equatable {
  final AnalysisStatus status;
  final AnalysisResult? result;
  final String? errorMessage;
  final double uploadProgress;

  const AnalysisState({
    this.status = AnalysisStatus.initial,
    this.result,
    this.errorMessage,
    this.uploadProgress = 0.0,
  });

  AnalysisState copyWith({
    AnalysisStatus? status,
    AnalysisResult? result,
    String? errorMessage,
    double? uploadProgress,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage, uploadProgress];
}
