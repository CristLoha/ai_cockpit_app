part of 'file_picker_cubit.dart';

class SelectedFile extends Equatable {
  final String fileName;
  final String filePath;

  const SelectedFile({required this.fileName, required this.filePath});

  @override
  List<Object> get props => [fileName, filePath];
}

class FilePickerState extends Equatable {
  final List<SelectedFile> selectedFiles;

  const FilePickerState({this.selectedFiles = const []});

  FilePickerState copyWith({List<SelectedFile>? selectedFiles}) {
    return FilePickerState(selectedFiles: selectedFiles ?? this.selectedFiles);
  }

  @override
  List<Object> get props => [selectedFiles];
}
