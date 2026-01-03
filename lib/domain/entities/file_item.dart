import 'package:equatable/equatable.dart';
import '../value_objects/file_category.dart';

class FileItem extends Equatable {
  final String id;
  final String name;
  final String path;
  final int sizeInBytes;
  final DateTime lastModified;
  final String extension;
  final FileCategory category;
  final bool isSelected;

  const FileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeInBytes,
    required this.lastModified,
    required this.extension,
    required this.category,
    this.isSelected = false,
  });
  FileItem copyWith({bool? isSelected}) {
    return FileItem(
      id: id,
      name: name,
      path: path,
      sizeInBytes: sizeInBytes,
      lastModified: lastModified,
      extension: extension,
      category: category,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    path,
    sizeInBytes,
    lastModified,
    extension,
    category,
    isSelected,
  ];
}
