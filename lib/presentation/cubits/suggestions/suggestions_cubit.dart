import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_cleaning_suggestions_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/suggestions/suggestions_state.dart';

/// Cubit responsible for loading smart cleaning suggestions for the dashboard.
///
/// Business logic (rules, thresholds, analysis) lives in
/// [GetCleaningSuggestionsUseCase]. This Cubit only orchestrates loading
/// and exposes UI-friendly states.
class SuggestionsCubit extends Cubit<SuggestionsState> {
  final GetCleaningSuggestionsUseCase _getCleaningSuggestionsUseCase;

  SuggestionsCubit({
    required GetCleaningSuggestionsUseCase getCleaningSuggestionsUseCase,
  })  : _getCleaningSuggestionsUseCase = getCleaningSuggestionsUseCase,
        super(const SuggestionsInitial());

  Future<void> loadSuggestions() async {
    emit(const SuggestionsLoading());
    try {
      final suggestions = await _getCleaningSuggestionsUseCase.execute();
      emit(SuggestionsLoaded(suggestions: suggestions));
      Logger.info(
        '[SuggestionsCubit] Loaded ${suggestions.length} cleaning suggestions',
      );
    } catch (e) {
      Logger.error('[SuggestionsCubit] Failed to load suggestions', e);
      emit(
        const SuggestionsError(
          'Failed to load cleaning suggestions. Please try again later.',
        ),
      );
    }
  }

  Future<void> refresh() async {
    // Simple alias to reload suggestions without changing state type
    await loadSuggestions();
  }
}