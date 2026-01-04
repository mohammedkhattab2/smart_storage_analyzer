import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/dashboard_viewmodel.dart';

/// Cubit for managing Dashboard UI state
/// Follows MVVM pattern - delegates business logic to ViewModel
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardViewModel _viewModel;

  DashboardCubit({required DashboardViewModel viewModel})
      : _viewModel = viewModel,
        super(DashboardInitial());

  Future<void> loadDashboardData({BuildContext? context}) async {
    emit(DashboardLoading());
    try {
      final data = await _viewModel.loadDashboardData(context: context);
      
      emit(
        DashboardLoaded(
          storageInfo: data.storageInfo,
          categories: data.categories,
        ),
      );

      // Start background refresh to keep data current
      _startBackgroundRefresh();
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
      final data = await _viewModel.loadDashboardData(context: context);
      
      emit(
        DashboardLoaded(
          storageInfo: data.storageInfo,
          categories: data.categories,
        ),
      );
    } catch (e) {
      // Don't show error on refresh failure
    }
  }

  /// Start background refresh to keep data current
  void _startBackgroundRefresh() {
    // Refresh data every 30 seconds if the dashboard is loaded
    Future.delayed(const Duration(seconds: 30), () {
      if (state is DashboardLoaded && !isClosed) {
        refresh().then((_) => _startBackgroundRefresh());
      }
    });
  }

  @override
  Future<void> close() {
    // Cleanup if needed
    return super.close();
  }
}
