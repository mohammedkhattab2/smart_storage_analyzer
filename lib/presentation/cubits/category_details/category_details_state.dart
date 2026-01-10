import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';

abstract class CategoryDetailsState extends Equatable {
  const CategoryDetailsState();

  @override
  List<Object?> get props => [];
}

class CategoryDetailsInitial extends CategoryDetailsState {}

class CategoryDetailsLoading extends CategoryDetailsState {}

class CategoryDetailsLoaded extends CategoryDetailsState {
  final List<FileItem> files;
  final String categoryName;
  final int totalSize;
  final bool isSelectionMode;
  final Set<String> selectedFileIds;

  const CategoryDetailsLoaded({
    required this.files,
    required this.categoryName,
    required this.totalSize,
    this.isSelectionMode = false,
    this.selectedFileIds = const {},
  });

  // Helper getters
  bool get hasSelection => selectedFileIds.isNotEmpty;
  int get selectedCount => selectedFileIds.length;
  
  // Get selected files
  List<FileItem> get selectedFiles =>
      files.where((file) => selectedFileIds.contains(file.id)).toList();
  
  // Get total size of selected files
  int get selectedSize => selectedFiles.fold<int>(
        0,
        (sum, file) => sum + file.sizeInBytes,
      );
  
  // Check if a specific file is selected
  bool isFileSelected(String fileId) => selectedFileIds.contains(fileId);
  
  // Create a copy with updated values
  CategoryDetailsLoaded copyWith({
    List<FileItem>? files,
    String? categoryName,
    int? totalSize,
    bool? isSelectionMode,
    Set<String>? selectedFileIds,
  }) {
    return CategoryDetailsLoaded(
      files: files ?? this.files,
      categoryName: categoryName ?? this.categoryName,
      totalSize: totalSize ?? this.totalSize,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
    );
  }

  @override
  List<Object?> get props => [files, categoryName, totalSize, isSelectionMode, selectedFileIds];
}

class CategoryDetailsError extends CategoryDetailsState {
  final String message;

  const CategoryDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
