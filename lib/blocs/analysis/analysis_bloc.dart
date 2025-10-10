import 'dart:io';
import 'dart:developer' as developer;
import 'package:ai_cockpit_app/blocs/file_picker/file_picker_cubit.dart';
import 'package:ai_cockpit_app/data/models/analysis_result.dart';
import 'package:ai_cockpit_app/data/repositories/chat_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'analysis_event.dart';

part 'analysis_state.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final ChatRepository _chatRepository;

  final FilePickerCubit _filePickerCubit;

  AnalysisBloc({
    required ChatRepository chatRepository,
    required FilePickerCubit filePickerCubit,
  }) : _chatRepository = chatRepository,
       _filePickerCubit = filePickerCubit,
       super(const AnalysisState()) {
    on<AnalysisDocumentRequested>(_onAnalysisDocumentRequested);
    on<_AnalysisProgressUpdated>(_onAnalysisProgressUpdated);
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

    try {
      final selectedFile = files.first;
      final fileBytes = await File(selectedFile.filePath).readAsBytes();

      final result = await _chatRepository.analyzeNewDocument(
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
