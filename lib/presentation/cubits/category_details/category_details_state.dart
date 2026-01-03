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

  const CategoryDetailsLoaded({
    required this.files,
    required this.categoryName,
    required this.totalSize,
  });

  @override
  List<Object?> get props => [files, categoryName, totalSize];
}

class CategoryDetailsError extends CategoryDetailsState {
  final String message;

  const CategoryDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
