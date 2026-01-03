import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_state.dart';

class CategoryDetailsCubit extends Cubit<CategoryDetailsState> {
  final GetFilesUsecase getFilesUsecase;

  CategoryDetailsCubit({required this.getFilesUsecase})
    : super(CategoryDetailsInitial());

  Future<void> loadCategoryFiles(Category category) async {
    emit(CategoryDetailsLoading());

    try {
      // Convert category name to FileCategory enum
      final fileCategory = _mapCategoryToFileCategory(category.name);

      // Fetch files for this category
      final files = await getFilesUsecase.excute(fileCategory);

      // Sort files by modification date (newest first)
      files.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      // Calculate total size
      final totalSize = files.fold<int>(
        0,
        (sum, file) => sum + file.sizeInBytes,
      );

      emit(
        CategoryDetailsLoaded(
          files: files,
          categoryName: category.name,
          totalSize: totalSize,
        ),
      );
    } catch (e) {
      emit(
        CategoryDetailsError(
          'Failed to load ${category.name} files: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> refresh(Category category) async {
    await loadCategoryFiles(category);
  }

  FileCategory _mapCategoryToFileCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'images':
      case 'image':
        return FileCategory.images;
      case 'videos':
      case 'video':
        return FileCategory.videos;
      case 'audio':
      case 'music':
        return FileCategory.audio;
      case 'documents':
      case 'document':
        return FileCategory.documents;
      case 'apps':
      case 'applications':
        return FileCategory.apps;
      case 'all':
        return FileCategory.all;
      case 'large':
        return FileCategory.large;
      case 'duplicates':
        return FileCategory.duplicates;
      case 'old':
        return FileCategory.old;
      default:
        return FileCategory.others;
    }
  }
}
