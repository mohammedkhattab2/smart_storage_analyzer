import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/dashboard_viewmodel.dart';

/// Cubit for managing Dashboard UI state
/// Follows MVVM pattern - delegates business logic to ViewModel
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardViewModel _viewModel;
  bool _isRefreshing = false;
  bool _hasLoadedInitialData = false;
  DateTime? _lastLoadTime;
  static const Duration _minimumRefreshInterval = Duration(minutes: 5);

  DashboardCubit({required DashboardViewModel viewModel})
    : _viewModel = viewModel,
      super(DashboardInitial());

  Future<void> loadDashboardData({BuildContext? context, bool forceReload = false}) async {
    // Skip loading if data already loaded and not forcing reload
    if (_hasLoadedInitialData && !forceReload && state is DashboardLoaded) {
      // Check if enough time has passed for background refresh
      if (_lastLoadTime != null &&
          DateTime.now().difference(_lastLoadTime!) < _minimumRefreshInterval) {
        return;
      }
    }

    // Don't show loading state if we already have data (just refreshing)
    if (!_hasLoadedInitialData || forceReload) {
      emit(DashboardLoading());
    }
    
    try {
      final data = await _viewModel.loadDashboardData(
        context: context,
        forceReload: forceReload
      );

      _hasLoadedInitialData = true;
      _lastLoadTime = DateTime.now();

      emit(
        DashboardLoaded(
          storageInfo: data.storageInfo,
          categories: data.categories,
        ),
      );

      // Start background refresh to keep data current (but less frequently)
      if (!_isRefreshing) {
        _startBackgroundRefresh();
      }
    } catch (e) {
      if (e is PermissionException) {
        emit(DashboardError(message: e.toString()));
      } else {
        emit(
          DashboardError(
            message: "Failed to load storage data: ${e.toString()}",
          ),
        );
      }
    }
  }

  Future<void> analyzeAndClean() async {
    // Navigation to storage analysis screen will be handled in the UI layer
    // This method is kept for compatibility but the actual navigation
    // happens in the dashboard content widget
  }

  Future<void> refresh({BuildContext? context}) async {
    // Don't show loading state for refresh to avoid UI flicker
    try {
      final data = await _viewModel.loadDashboardData(
        context: context,
        forceReload: false // Don't force reload on background refresh
      );

      if (state is DashboardLoaded || _hasLoadedInitialData) {
        emit(
          DashboardLoaded(
            storageInfo: data.storageInfo,
            categories: data.categories,
          ),
        );
      }
    } catch (e) {
      // Don't show error on refresh failure, keep the existing data
    }
  }

  /// Check if dashboard has loaded initial data
  bool get hasLoadedData => _hasLoadedInitialData;

  /// Start background refresh to keep data current
  void _startBackgroundRefresh() {
    if (_isRefreshing || isClosed) return;
    
    _isRefreshing = true;
    // Refresh data every 5 minutes instead of 30 seconds
    Future.delayed(const Duration(minutes: 5), () {
      if (state is DashboardLoaded && !isClosed && _isRefreshing) {
        refresh().then((_) {
          if (!isClosed) {
            _startBackgroundRefresh();
          }
        });
      }
    });
  }

  @override
  Future<void> close() {
    _isRefreshing = false; // Stop background refresh
    _viewModel.dispose(); // Dispose the view model
    return super.close();
  }
}
