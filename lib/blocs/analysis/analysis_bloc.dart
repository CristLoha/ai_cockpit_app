import 'dart:io';

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
    // DIUBAH: Tambahkan event handler untuk progress
    on<AnalysisDocumentRequested>(_onAnalysisDocumentRequested);
    on<_AnalysisProgressUpdated>(_onAnalysisProgressUpdated);
  }

  // DITAMBAHKAN: Method untuk handle update progress
  void _onAnalysisProgressUpdated(
      _AnalysisProgressUpdated event, Emitter<AnalysisState> emit) {
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

    // DIUBAH: Reset progress saat mulai
    emit(state.copyWith(status: AnalysisStatus.loading, uploadProgress: 0.0));
    try {
      final selectedFile = files.first;

      final fileBytes = await File(selectedFile.filePath).readAsBytes();

      // DIUBAH: Kirim callback ke repository
      final result = await _chatRepository.analyzeNewDocument(
        fileName: selectedFile.fileName,
        fileBytes: fileBytes,
        onProgress: (progress) {
          // Tambahkan event baru untuk update progress di BLoC
          if (!isClosed) {
            add(_AnalysisProgressUpdated(progress));
          }
        },
      );

      _filePickerCubit.clearFiles();
      emit(state.copyWith(status: AnalysisStatus.success, result: result, uploadProgress: 1.0));
    } catch (e) {
      emit(
        state.copyWith(
          status: AnalysisStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
