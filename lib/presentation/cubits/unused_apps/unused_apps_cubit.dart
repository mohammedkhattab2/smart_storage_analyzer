import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/entities/unused_app.dart';
import 'package:smart_storage_analyzer/domain/errors/unused_apps_failures.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_unused_apps_usecase.dart';

part 'unused_apps_state.dart';

/// Cubit responsible for managing the Unused Apps feature state.
///
/// Presentation layer only:
/// - Delegates all business logic to domain use cases
/// - Exposes simple states for the UI to render
class UnusedAppsCubit extends Cubit<UnusedAppsState> {
  final GetUnusedAppsUseCase _getUnusedAppsUseCase;

  UnusedAppsFilter _currentFilter = UnusedAppsFilter.days30;
  UnusedAppsSort _currentSort = UnusedAppsSort.byLastUsed;

  UnusedAppsCubit({
    required GetUnusedAppsUseCase getUnusedAppsUseCase,
  })  : _getUnusedAppsUseCase = getUnusedAppsUseCase,
        super(UnusedAppsInitial());

  UnusedAppsFilter get currentFilter => _currentFilter;
  UnusedAppsSort get currentSort => _currentSort;

  Future<void> loadUnusedApps({
    UnusedAppsFilter? filter,
    UnusedAppsSort? sort,
  }) async {
    final effectiveFilter = filter ?? _currentFilter;
    final effectiveSort = sort ?? _currentSort;

    _currentFilter = effectiveFilter;
    _currentSort = effectiveSort;

    emit(UnusedAppsLoading(
      filter: effectiveFilter,
      sort: effectiveSort,
    ));

    try {
      final apps = await _getUnusedAppsUseCase.execute(
        filter: effectiveFilter,
        sort: effectiveSort,
      );

      final totalReclaimableBytes = apps.fold<int>(
        0,
        (sum, app) => sum + app.appSizeBytes,
      );

      emit(UnusedAppsLoaded(
        apps: apps,
        totalReclaimableBytes: totalReclaimableBytes,
        filter: effectiveFilter,
        sort: effectiveSort,
      ));
    } on UsageAccessDeniedFailure catch (e) {
      Logger.warning(
        '[UnusedAppsCubit] Usage access permission required: ${e.message}',
      );
      emit(UnusedAppsPermissionRequired(
        message: e.message,
        filter: effectiveFilter,
        sort: effectiveSort,
      ));
    } catch (e) {
      Logger.error('[UnusedAppsCubit] Failed to load unused apps', e);
      emit(UnusedAppsError(
        message: 'Failed to load unused apps. Please try again.',
        filter: effectiveFilter,
        sort: effectiveSort,
      ));
    }
  }

  /// Public API for explicitly refreshing the unused apps list.
  ///
  /// This is used by the UI after uninstall operations complete to ensure
  /// the list reflects the latest installed apps state.
  Future<void> refreshUnusedApps() async {
    await loadUnusedApps();
  }

  Future<void> changeFilter(UnusedAppsFilter filter) async {
    await loadUnusedApps(filter: filter, sort: _currentSort);
  }

  Future<void> changeSort(UnusedAppsSort sort) async {
    await loadUnusedApps(filter: _currentFilter, sort: sort);
  }

  /// Convenience getter for the total reclaimable size based on the
  /// currently loaded unused apps list. Returns 0 if not loaded.
  int get totalReclaimableBytes {
    final currentState = state;
    if (currentState is UnusedAppsLoaded) {
      return currentState.totalReclaimableBytes;
    }
    return 0;
  }
}