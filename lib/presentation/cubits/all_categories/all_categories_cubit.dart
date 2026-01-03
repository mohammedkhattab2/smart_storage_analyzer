import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/all_categories/all_categories_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/all_categories_viewmodel.dart';

class AllCategoriesCubit extends Cubit<AllCategoriesState> {
  final AllCategoriesViewModel viewModel;

  AllCategoriesCubit({required this.viewModel}) : super(AllCategoriesInitial());

  void loadCategories(List<Category> categories) async {
    emit(AllCategoriesLoading());

    try {
      // Simulate a small delay for animation
      await Future.delayed(const Duration(milliseconds: 300));

      // Calculate total storage from all categories
      final totalStorage = categories.fold<int>(
        0,
        (sum, category) => sum + category.sizeInBytes.toInt(),
      );

      // Sort categories by size (largest first)
      final sortedCategories = List<Category>.from(categories)
        ..sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));

      emit(
        AllCategoriesLoaded(
          categories: sortedCategories,
          totalStorage: totalStorage,
        ),
      );
    } catch (e) {
      emit(AllCategoriesError('Failed to load categories: ${e.toString()}'));
    }
  }

  Future<void> refresh() async {
    if (state is AllCategoriesLoaded) {
      final currentState = state as AllCategoriesLoaded;
      loadCategories(currentState.categories);
    }
  }
}
