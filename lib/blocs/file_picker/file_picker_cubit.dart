import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

part 'file_picker_state.dart';

class FilePickerCubit extends Cubit<FilePickerState> {
  FilePickerCubit() : super(const FilePickerState());

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      allowMultiple: true,
    );

    if (result != null) {
      // Salin daftar file yang sudah ada
      final updatedFiles = List<SelectedFile>.from(state.selectedFiles);
      final existingFileNames = updatedFiles.map((f) => f.fileName).toSet();

      for (var file in result.files) {
        // Tambahkan hanya jika file belum ada di daftar
        if (file.path != null && !existingFileNames.contains(file.name)) {
          final fileBytes = await File(file.path!).readAsBytes();
          updatedFiles.add(
            SelectedFile(fileName: file.name, fileBytes: fileBytes),
          );
        }
      }
      emit(state.copyWith(selectedFiles: updatedFiles));
    }
  }

  void removeFile(String fileName) {
    final newFiles = List<SelectedFile>.from(state.selectedFiles)
      ..removeWhere((file) => file.fileName == fileName);
    emit(state.copyWith(selectedFiles: newFiles));
  }

  void clearFiles() {
    emit(state.copyWith(selectedFiles: []));
  }
}
