import 'package:equatable/equatable.dart';
import '../../../domain/entities/file_item.dart';
import '../../../domain/value_objects/file_category.dart';

abstract class FileManagerState extends Equatable {
  const FileManagerState();

  @override
  List<Object?> get props => [];
}

class FileManagerInitial extends FileManagerState {}

class FileManagerLoading extends FileManagerState {}

class FileManagerLoaded extends FileManagerState {
  final List<FileItem> files;
  final FileCategory currentCategory;
  final Set<String> selectedFileIds;

  const FileManagerLoaded({
    required this.files,
    required this.currentCategory,
    this.selectedFileIds = const {},
  });

  int get selectedCount => selectedFileIds.length;

  int get selectedSize {
    return files
        .where((file) => selectedFileIds.contains(file.id))
        .fold(0, (sum, file) => sum + file.sizeInBytes);
  }

  @override
  List<Object?> get props => [files, currentCategory, selectedFileIds];

  FileManagerLoaded copyWith({
    List<FileItem>? files,
    FileCategory? currentCategory,
    Set<String>? selectedFileIds,
  }) {
    return FileManagerLoaded(
      files: files ?? this.files,
      currentCategory: currentCategory ?? this.currentCategory,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
    );
  }
}

class FileManagerDeleting extends FileManagerState {
  final String message;

  const FileManagerDeleting({this.message = 'Deleting files...'});

  @override
  List<Object?> get props => [message];
}

class FileManagerError extends FileManagerState {
  final String message;

  const FileManagerError(this.message);

  @override
  List<Object?> get props => [message];
}
