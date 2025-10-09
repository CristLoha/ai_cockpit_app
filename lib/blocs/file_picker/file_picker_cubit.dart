import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

part 'file_picker_state.dart';

class FilePickerCubit extends Cubit<FilePickerState> {
  FilePickerCubit() : super(const FilePickerState());

  Future<void> pickSingleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;

      emit(
        state.copyWith(
          selectedFiles: [
            SelectedFile(fileName: file.name, filePath: file.path!),
          ],
        ),
      );
    }
  }

  void clearFiles() {
    emit(state.copyWith(selectedFiles: []));
  }
}
