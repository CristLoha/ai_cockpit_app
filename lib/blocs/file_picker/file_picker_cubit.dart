import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

part 'file_picker_state.dart';

class FilePickerCubit extends Cubit<FilePickerState> {
  FilePickerCubit() : super(const FilePickerState());

  // Fungsi untuk memilih satu file
  Future<void> pickSingleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      allowMultiple: false, // Pastikan hanya satu file
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;

      // HANYA SIMPAN NAMA & PATH FILE, JANGAN BACA BYTE DI SINI
      emit(
        state.copyWith(
          selectedFiles: [
            SelectedFile(fileName: file.name, filePath: file.path!),
          ],
        ),
      );
    }
  }

  // Fungsi untuk membersihkan file
  void clearFiles() {
    emit(state.copyWith(selectedFiles: []));
  }
}
