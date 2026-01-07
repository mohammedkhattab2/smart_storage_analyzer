part of 'cleanup_results_cubit.dart';

abstract class CleanupResultsState extends Equatable {
  const CleanupResultsState();

  @override
  List<Object?> get props => [];
}

class CleanupResultsInitial extends CleanupResultsState {}

class CleanupResultsLoaded extends CleanupResultsState {
  final StorageAnalysisResults results;
  final Set<String> selectedCategories;
  final Map<String, Set<String>> selectedFiles;

  const CleanupResultsLoaded({
    required this.results,
    required this.selectedCategories,
    required this.selectedFiles,
  });

  @override
  List<Object> get props => [results, selectedCategories, selectedFiles];

  CleanupResultsLoaded copyWith({
    StorageAnalysisResults? results,
    Set<String>? selectedCategories,
    Map<String, Set<String>>? selectedFiles,
  }) {
    return CleanupResultsLoaded(
      results: results ?? this.results,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedFiles: selectedFiles ?? this.selectedFiles,
    );
  }

  // Calculate total selected size
  int get totalSelectedSize {
    int total = 0;
    for (final category in results.cleanupCategories) {
      final categoryFiles = selectedFiles[category.name];
      if (categoryFiles != null) {
        total += category.files
            .where((file) => categoryFiles.contains(file.id))
            .fold(0, (sum, file) => sum + file.sizeInBytes);
      }
    }
    return total;
  }

  // Get selected files count
  int get selectedFilesCount {
    int count = 0;
    for (final files in selectedFiles.values) {
      count += files.length;
    }
    return count;
  }
}

class CleanupInProgress extends CleanupResultsState {
  final String message;
  final double progress;

  const CleanupInProgress({required this.message, required this.progress});

  @override
  List<Object> get props => [message, progress];
}

class CleanupCompleted extends CleanupResultsState {
  final int filesDeleted;
  final int spaceFreed;

  const CleanupCompleted({
    required this.filesDeleted,
    required this.spaceFreed,
  });

  @override
  List<Object> get props => [filesDeleted, spaceFreed];
}

class CleanupError extends CleanupResultsState {
  final String message;

  const CleanupError({required this.message});

  @override
  List<Object> get props => [message];
}
