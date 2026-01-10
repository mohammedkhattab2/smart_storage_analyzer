import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/all_categories/all_categories_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/all_categories_viewmodel.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_categories_usecase.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

class AllCategoriesCubit extends Cubit<AllCategoriesState> {
  final AllCategoriesViewModel viewModel;
  final GetCategoriesUseCase? _getCategoriesUseCase;
  List<Category>? _initialCategories;

  AllCategoriesCubit({
    required this.viewModel,
    GetCategoriesUseCase? getCategoriesUseCase,
  }) : _getCategoriesUseCase = getCategoriesUseCase,
       super(AllCategoriesInitial());

  void loadCategories(List<Category> categories) async {
    emit(AllCategoriesLoading());
    _initialCategories = categories; // Store initial categories

    try {
      // Try to fetch fresh categories from repository (which includes SAF data)
      List<Category> freshCategories;
      
      if (_getCategoriesUseCase != null) {
        try {
          Logger.info('Fetching fresh categories with SAF data...');
          freshCategories = await _getCategoriesUseCase.excute();
          Logger.info('Got fresh categories including Documents with SAF data');
        } catch (e) {
          Logger.warning('Failed to fetch fresh categories, using provided ones: $e');
          freshCategories = categories;
        }
      } else {
        freshCategories = categories;
      }

      // Calculate total storage from all categories
      final totalStorage = freshCategories.fold<int>(
        0,
        (sum, category) => sum + category.sizeInBytes.toInt(),
      );

      // Sort categories by size (largest first)
      final sortedCategories = List<Category>.from(freshCategories)
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
    // Always fetch fresh categories on refresh
    if (_initialCategories != null) {
      loadCategories(_initialCategories!);
    } else if (state is AllCategoriesLoaded) {
      final currentState = state as AllCategoriesLoaded;
      loadCategories(currentState.categories);
    }
  }
}
