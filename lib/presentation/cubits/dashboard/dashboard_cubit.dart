import 'dart:ffi';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/errors/app_errors.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/domain/usecases/analyze_storage_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_categories_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_storage_info_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetStorageInfoUsecase getStorageInfoUsecase;
  final GetCategoriesUsecase getCategoriesUsecase;
  final AnalyzeStorageUsecase analyzeStorageUsecase;

  DashboardCubit({
    required this.getStorageInfoUsecase,
    required this.getCategoriesUsecase,
    required this.analyzeStorageUsecase,
  }) : super(DashboardInitial());

  Future<void> loadDashboardData() async {
    emit(DashboardLoading());
    try {
      final results = await Future.wait([
        getStorageInfoUsecase.excute(),
        getCategoriesUsecase.excute(),
      ]);
      final storageInfo = results[0] as dynamic;
      final categories = results[1] as List<dynamic>;

      emit(
        dashboardLoaded(
          storageInfo: storageInfo,
          categories: categories.cast(),
        ),
      );
      Logger.success("Dashboard data loaded successfully");
    } catch (e) {
      Logger.error('Failed to load dashboard data', e);
      if (e is PermissionError) {
        emit(DashboardError(message: "Storage permission is required"));
      } else {
        emit(DashboardError(message: "Failed to load storage data"));
      }
    }
  }

  Future<void> analyzeAndClean() async {
    try {
      emit(DashboardAnalyzing());
      await analyzeStorageUsecase.excute();
      await loadDashboardData();
    } catch (e) {
      Logger.error('Failed to analyze storage', e);
      emit(DashboardError(message: 'Analysis failed. Please try again.'));
    }
  }
  Future <void> refresh ()async {
    await loadDashboardData();
  }
}
