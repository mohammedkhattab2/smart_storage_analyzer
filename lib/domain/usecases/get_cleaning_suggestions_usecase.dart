import 'package:smart_storage_analyzer/domain/entities/cleaning_suggestion.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/entities/unused_app.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';
import 'package:smart_storage_analyzer/domain/repositories/unused_apps_repository.dart';

/// Generates high-level smart cleaning suggestions for the dashboard.
///
/// This use case evaluates:
/// - Cache size (from deep storage analysis)
/// - Unused apps count and size
/// - Large / old files detected by analysis
///
/// It returns a list of [CleaningSuggestion] without any UI concerns.
class GetCleaningSuggestionsUseCase {
  final StorageRepository _storageRepository;
  final UnusedAppsRepository _unusedAppsRepository;

  // Because we only have access to this app's own cache, use a lower threshold
  // so that users can actually see suggestions when our cache grows.
  // 50 MB in bytes
  static const int _cacheThresholdBytes = 50 * 1024 * 1024;
  // Default inactivity threshold for considering apps as "unused"
  static const int _unusedAppsDaysThreshold = 30;
  // Minimal large-files total threshold to show the suggestion (e.g. 500 MB)
  static const int _largeFilesThresholdBytes = 500 * 1024 * 1024;
  // Cache time-to-live for suggestions.
  static const Duration _cacheTtl = Duration(minutes: 5);

  // In-memory cache for suggestions. Lives inside the use case instance so it
  // stays in the domain layer and is not global/static.
  List<CleaningSuggestion>? _cachedSuggestions;
  DateTime? _lastCacheUpdate;

  GetCleaningSuggestionsUseCase(
    this._storageRepository,
    this._unusedAppsRepository,
  );

  Future<List<CleaningSuggestion>> execute() async {
    final now = DateTime.now();
    final lastUpdate = _lastCacheUpdate;

    // Return cached value when still fresh.
    if (_cachedSuggestions != null &&
        lastUpdate != null &&
        now.difference(lastUpdate) <= _cacheTtl) {
      // Return a defensive copy to avoid accidental external mutation.
      return List<CleaningSuggestion>.unmodifiable(_cachedSuggestions!);
    }

    // Perform deep analysis once and reuse its results
    final StorageAnalysisResults analysisResults =
        await _storageRepository.performDeepAnalysis();

    // Get unused apps list for the configured inactivity period
    final List<UnusedApp> unusedApps = await _unusedAppsRepository.getUnusedApps(
      minDaysUnused: _unusedAppsDaysThreshold,
    );

    final List<CleaningSuggestion> suggestions = [];

    _addCacheSuggestionIfNeeded(analysisResults, suggestions);
    _addUnusedAppsSuggestionIfNeeded(unusedApps, suggestions);
    _addLargeFilesSuggestionIfNeeded(analysisResults, suggestions);

    // Update cache after successful recompute.
    _cachedSuggestions = List<CleaningSuggestion>.unmodifiable(suggestions);
    _lastCacheUpdate = now;

    return _cachedSuggestions!;
  }

  void _addCacheSuggestionIfNeeded(
    StorageAnalysisResults analysisResults,
    List<CleaningSuggestion> suggestions,
  ) {
    final int totalCacheSize = analysisResults.totalCacheSize;

    if (totalCacheSize > _cacheThresholdBytes) {
      suggestions.add(
        CleaningSuggestion(
          id: 'cache_cleanup',
          title: 'Clear this app\'s cache',
          description:
              'You can clear temporary cache used by this app to free some space. '
              'Cache from other apps must be cleared from the system settings.',
          actionType: CleaningSuggestionActionType.cleanCache,
          potentialSpaceSaved: totalCacheSize,
        ),
      );
    }
  }

  void _addUnusedAppsSuggestionIfNeeded(
    List<UnusedApp> unusedApps,
    List<CleaningSuggestion> suggestions,
  ) {
    if (unusedApps.length > 3) {
      final int totalUnusedAppsSize = unusedApps.fold<int>(
        0,
        (sum, app) => sum + app.appSizeBytes,
      );

      suggestions.add(
        CleaningSuggestion(
          id: 'unused_apps',
          title: 'Remove unused apps',
          description:
              'You have several apps that you have not opened in a long time. Uninstalling unused apps can free up valuable space.',
          actionType: CleaningSuggestionActionType.showUnusedApps,
          potentialSpaceSaved: totalUnusedAppsSize,
        ),
      );
    }
  }

  void _addLargeFilesSuggestionIfNeeded(
    StorageAnalysisResults analysisResults,
    List<CleaningSuggestion> suggestions,
  ) {
    final int totalLargeOldSize = analysisResults.totalLargeOldSize;

    if (totalLargeOldSize > _largeFilesThresholdBytes) {
      suggestions.add(
        CleaningSuggestion(
          id: 'large_files',
          title: 'Review large files',
          description:
              'Large files and downloads are taking up significant space. Review and delete files you no longer need.',
          actionType: CleaningSuggestionActionType.showLargeFiles,
          potentialSpaceSaved: totalLargeOldSize,
        ),
      );
    }
  }
}