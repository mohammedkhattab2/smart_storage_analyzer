import '../../domain/entities/file_item.dart';
import '../../domain/value_objects/file_category.dart';

class FileItemModel extends FileItem {
  const FileItemModel({
    required String id,
    required String name,
    required String path,
    required int sizeInBytes,
    required DateTime lastModified,
    required String extension,
    required FileCategory category,
    bool isSelected = false,
  }) : super(
         id: id,
         name: name,
         path: path,
         sizeInBytes: sizeInBytes,
         lastModified: lastModified,
         extension: extension,
         category: category,
         isSelected: isSelected,
       );

  factory FileItemModel.fromJson(Map<String, dynamic> json) {
    return FileItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      sizeInBytes: json['sizeInBytes'] ?? 0,
      lastModified: DateTime.parse(json['lastModified']),
      extension: json['extension'] ?? '',
      category: FileCategoryExtension.fromString(json['category'] ?? 'others'),
      isSelected: json['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'sizeInBytes': sizeInBytes,
      'lastModified': lastModified.toIso8601String(),
      'extension': extension,
      'category': category.toJson(),
      'isSelected': isSelected,
    };
  }

  factory FileItemModel.fromFileSystemEntity({
    required String path,
    required DateTime lastModified,
    required int size,
  }) {
    final name = path.split('/').last;
    final extension = name.contains('.') ? '.${name.split('.').last}' : '';

    return FileItemModel(
      id: path.hashCode.toString(),
      name: name,
      path: path,
      sizeInBytes: size,
      lastModified: lastModified,
      extension: extension,
      category: FileCategoryExtension.fromExtension(extension),
    );
  }
}
