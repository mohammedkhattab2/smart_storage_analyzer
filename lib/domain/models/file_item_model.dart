import '../../domain/entities/file_item.dart';
import '../../domain/value_objects/file_category.dart';

class FileItemModel extends FileItem {
  const FileItemModel({
    required super.id,
    required super.name,
    required super.path,
    required super.sizeInBytes,
    required super.lastModified,
    required super.extension,
    required super.category,
    super.isSelected,
  });

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
