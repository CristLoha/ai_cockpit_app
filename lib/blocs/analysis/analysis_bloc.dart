import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/blocs/auth/auth_cubit.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:ai_cockpit_app/data/repositories/chat_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

part 'analysis_event.dart';

part 'analysis_state.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final ChatRepository _chatRepository;

  final FilePickerCubit _filePickerCubit;

  final AuthCubit _authCubit;
  late final StreamSubscription _authSubscription;

  CancelToken? _cancelToken;

  AnalysisBloc({
    required ChatRepository chatRepository,
    required FilePickerCubit filePickerCubit,
    required AuthCubit authCubit,
  }) : _chatRepository = chatRepository,
       _filePickerCubit = filePickerCubit,
       _authCubit = authCubit,
       super(const AnalysisState()) {
    on<AnalysisDocumentRequested>(_onAnalysisDocumentRequested);
    on<_AnalysisProgressUpdated>(_onAnalysisProgressUpdated);
    on<AnalysisCancelled>(_onAnalysisCancelled);
    on<AnalysisReset>(_onAnalysisReset);

    _authSubscription = _authCubit.stream.listen((authState) {
      if (state.status == AnalysisStatus.loading) {
        add(AnalysisCancelled());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    _cancelToken?.cancel();
    return super.close();
  }

  void _onAnalysisCancelled(
    AnalysisCancelled event,
    Emitter<AnalysisState> emit,
  ) {
    _cancelToken?.cancel('Analysis cancelled by user');
    _cancelToken = null;
    emit(state.copyWith(status: AnalysisStatus.initial, uploadProgress: 0.0));
  }

  void _onAnalysisReset(AnalysisReset event, Emitter<AnalysisState> emit) {
    emit(const AnalysisState());
  }

  void _onAnalysisProgressUpdated(
    _AnalysisProgressUpdated event,
    Emitter<AnalysisState> emit,
  ) {
    emit(state.copyWith(uploadProgress: event.progress));
  }

  Future<void> _onAnalysisDocumentRequested(
    AnalysisDocumentRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    final files = _filePickerCubit.state.selectedFiles;
    if (files.isEmpty) {
      emit(
        state.copyWith(
          status: AnalysisStatus.failure,
          errorMessage: "Tidak ada file yang dipilih.",
        ),
      );
      return;
    }

    emit(state.copyWith(status: AnalysisStatus.loading, uploadProgress: 0.0));

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final selectedFile = files.first;
      final fileBytes = await File(selectedFile.filePath).readAsBytes();

      final result = await _chatRepository.analyzeNewDocument(
        cancelToken: _cancelToken,
        fileName: selectedFile.fileName,
        fileBytes: fileBytes,
        onProgress: (progress) {
          if (!isClosed) {
            add(_AnalysisProgressUpdated(progress));
          }
        },
      );

      _filePickerCubit.clearFiles();
      emit(
        state.copyWith(
          status: AnalysisStatus.success,
          result: result,
          uploadProgress: 1.0,
        ),
      );
    } on DioException catch (e, stackTrace) {
      if (CancelToken.isCancel(e)) {
        developer.log('Analysis cancelled');
        emit(state.copyWith(status: AnalysisStatus.initial));
        return;
      }

      developer.log("PESAN ERROR: $e");
      developer.log("LOKASI FILE (STACK TRACE):");
      developer.log('$stackTrace');
      emit(
        state.copyWith(
          status: AnalysisStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    } catch (e, stackTrace) {
      developer.log("PESAN ERROR: $e");
      developer.log("LOKASI FILE (STACK TRACE):");
      developer.log('$stackTrace');
      emit(
        state.copyWith(
          status: AnalysisStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
