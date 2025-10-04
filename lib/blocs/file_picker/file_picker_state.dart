part of 'file_picker_cubit.dart';

 class FilePickerState extends Equatable {
  final List<SelectedFile> selectedFiles;

  const FilePickerState({this.selectedFiles = const []});

  FilePickerState copyWith({List<SelectedFile>? selectedFiles}) {
    return FilePickerState(
      selectedFiles: selectedFiles ?? this.selectedFiles,
    );
  }

  @override
  List<Object> get props => [selectedFiles];
}
class SelectedFile extends Equatable {
  final String fileName;
  final Uint8List fileBytes;

  const SelectedFile({required this.fileName, required this.fileBytes});

  @override
  List<Object> get props => [fileName];
}
