import 'package:equatable/equatable.dart';

/// Domain entity for Category - contains only business data
/// No UI/Flutter dependencies allowed in domain layer
class Category extends Equatable {
  final String id;
  final String name;
  final double sizeInBytes;
  final int fileCount;
  
  const Category({
    required this.id,
    required this.name,
    required this.sizeInBytes,
    required this.fileCount,
  });
  
  @override
  List<Object?> get props => [id, name, sizeInBytes, fileCount];
}
