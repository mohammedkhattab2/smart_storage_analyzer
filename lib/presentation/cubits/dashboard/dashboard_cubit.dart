import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/errors/app_errors.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/usecases/analyze_storage_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_categories_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_storage_info_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetStorageInfoUsecase getStorageInfoUsecase;
  final GetCategoriesUsecase getCategoriesUsecase;
  final AnalyzeStorageUsecase analyzeStorageUsecase;

  DashboardCubit({
    required this.getStorageInfoUsecase,
    required this.getCategoriesUsecase,
    required this.analyzeStorageUsecase,
  }) : super(DashboardInitial()) {
    // Load dashboard data when cubit is created
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    emit(DashboardLoading());
    try {
      // Check and request storage permission for Android
      if (await _requestStoragePermission()) {
        // Load storage info and categories in parallel for better performance
        final results = await Future.wait([
          getStorageInfoUsecase.excute(),
          getCategoriesUsecase.excute(),
        ]);

        final storageInfo = results[0] as dynamic;
        final categories = results[1] as List<dynamic>;

        emit(
          DashboardLoaded(
            storageInfo: storageInfo,
            categories: categories.cast(),
          ),
        );

        Logger.success("Dashboard data loaded successfully");

        // Start background refresh to keep data current
        _startBackgroundRefresh();
      } else {
        emit(
          const DashboardError(
            message:
                "Storage permission is required to analyze your device storage",
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to load dashboard data', e);
      if (e is PermissionError) {
        emit(
          const DashboardError(
            message:
                "Storage permission is required to analyze your device storage",
          ),
        );
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
    try {
      final currentState = state;
      if (currentState is DashboardLoaded) {
        // Show analyzing state with current data
        emit(
          DashboardAnalyzing(
            message: "Scanning device storage...",
            storageInfo: currentState.storageInfo,
            categories: currentState.categories,
          ),
        );

        // Perform actual analysis
        await analyzeStorageUsecase.excute();

        // Update with progress
        emit(
          DashboardAnalyzing(
            message: "Analyzing file categories...",
            storageInfo: currentState.storageInfo,
            categories: currentState.categories,
            progress: 0.5,
          ),
        );

        // Reload data after analysis
        await loadDashboardData();
      }
    } catch (e) {
      Logger.error('Failed to analyze storage', e);
      emit(const DashboardError(message: 'Analysis failed. Please try again.'));

      // Try to reload previous state after error
      Future.delayed(const Duration(seconds: 2), () {
        loadDashboardData();
      });
    }
  }

  Future<void> refresh() async {
    // Don't show loading state for refresh to avoid UI flicker
    try {
      final results = await Future.wait([
        getStorageInfoUsecase.excute(),
        getCategoriesUsecase.excute(),
      ]);

      final storageInfo = results[0] as dynamic;
      final categories = results[1] as List<dynamic>;

      emit(
        DashboardLoaded(
          storageInfo: storageInfo,
          categories: categories.cast(),
        ),
      );
    } catch (e) {
      Logger.error('Failed to refresh dashboard', e);
      // Don't show error on refresh failure
    }
  }

  /// Request storage permission for Android
  Future<bool> _requestStoragePermission() async {
    try {
      // Skip permission check in debug mode for easier development
      if (kDebugMode) {
        Logger.info('Debug mode: Skipping permission check');
        return true;
      }

      // Check if we're on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return true;
      }
      return true; // Non-Android platforms
    } catch (e) {
      // If permission check fails, assume we have permission
      Logger.warning('Permission check failed: $e');
      return true;
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
