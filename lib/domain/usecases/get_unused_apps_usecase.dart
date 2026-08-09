import 'package:smart_storage_analyzer/domain/entities/unused_app.dart';
import 'package:smart_storage_analyzer/domain/repositories/unused_apps_repository.dart';

/// Supported filters for unused apps period.
enum UnusedAppsFilter {
  days7,
  days30,
  days60Plus,
}

/// Supported sorting modes for unused apps.
enum UnusedAppsSort {
  byLastUsed, // ascending: oldest used first
  bySizeDesc, // descending: largest first
}

/// Use case for fetching unused apps with configurable period and sorting.
///
/// This keeps all business rules in the domain layer:
/// - Filtering thresholds (7, 30, 60+ days)
/// - Sorting strategy (by last used time or by size)
class GetUnusedAppsUseCase {
  final UnusedAppsRepository _repository;

  GetUnusedAppsUseCase(this._repository);

  /// Execute the use case.
  ///
  /// [filter] controls the inactivity period:
  /// - [UnusedAppsFilter.days7]     -> last used >= 7 days ago
  /// - [UnusedAppsFilter.days30]    -> last used >= 30 days ago
  /// - [UnusedAppsFilter.days60Plus] -> last used >= 60 days ago
  ///
  /// [sort] controls how the resulting list is ordered.
  Future<List<UnusedApp>> execute({
    required UnusedAppsFilter filter,
    UnusedAppsSort sort = UnusedAppsSort.byLastUsed,
  }) async {
    final minDays = _mapFilterToDays(filter);
    final apps = await _repository.getUnusedApps(minDaysUnused: minDays);

    switch (sort) {
      case UnusedAppsSort.byLastUsed:
        apps.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
        break;
      case UnusedAppsSort.bySizeDesc:
        apps.sort((a, b) => b.appSizeBytes.compareTo(a.appSizeBytes));
        break;
    }

    return apps;
  }

  int _mapFilterToDays(UnusedAppsFilter filter) {
    switch (filter) {
      case UnusedAppsFilter.days7:
        return 7;
      case UnusedAppsFilter.days30:
        return 30;
      case UnusedAppsFilter.days60Plus:
        return 60;
    }
  }
}