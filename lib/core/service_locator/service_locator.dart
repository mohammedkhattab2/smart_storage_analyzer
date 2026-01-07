import 'package:get_it/get_it.dart';
import 'package:smart_storage_analyzer/data/repositories/file_repository_impl.dart';
import 'package:smart_storage_analyzer/data/repositories/settings_repository_impl.dart';
import 'package:smart_storage_analyzer/data/repositories/statistics_repository_impl.dart';
import 'package:smart_storage_analyzer/data/repositories/storage_repository_impl.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';
import 'package:smart_storage_analyzer/domain/repositories/statistics_repository.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/analyze_storage_use_case.dart';
import 'package:smart_storage_analyzer/domain/usecases/delete_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_categories_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_settings_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_statistics_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_storage_info_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/sign_out_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/update_settings_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_cubit.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/file_manager_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/optimized_file_manager_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/optimized_file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/statistics_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/all_categories_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_cubit.dart';
import 'package:smart_storage_analyzer/core/services/pro_access_service.dart';
import 'package:smart_storage_analyzer/core/services/feature_gate.dart';
import 'package:smart_storage_analyzer/data/repositories/pro_access_repository_impl.dart';
import 'package:smart_storage_analyzer/domain/repositories/pro_access_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/check_pro_feature_usecase.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/pro_access_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/cubits/pro_access/pro_access_cubit.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/storage_analysis_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/cubits/storage_analysis/storage_analysis_cubit.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/cleanup_results_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/cubits/cleanup_results/cleanup_results_cubit.dart';

final GetIt sl = GetIt.instance;
Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<StorageRepository>(() => StorageRepositoryImpl());
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetStorageInfoUseCase(sl()));

  // Dashboard ViewModel
  sl.registerLazySingleton(
    () => DashboardViewModel(
      getStorageInfoUsecase: sl(),
      getCategoriesUsecase: sl(),
      analyzeStorageUsecase: sl(),
    ),
  );

  // Dashboard Cubit
  sl.registerFactory(() => DashboardCubit(viewModel: sl()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  sl.registerLazySingleton(() => GetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSettingsUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerFactory(
    () => SettingsCubit(
      getSettingsUsecase: sl(),
      updateSettingsUsecase: sl(),
      signOutUsecase: sl(),
    ),
  );

  // Theme management
  sl.registerLazySingleton(() => ThemeCubit());

  // Repository
  sl.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepositoryImpl(storageRepository: sl<StorageRepository>()),
  );

  // UseCase
  sl.registerLazySingleton<GetStatisticsUseCase>(
    () => GetStatisticsUseCase(sl()),
  );

  // ViewModel
  sl.registerLazySingleton<StatisticsViewModel>(
    () => StatisticsViewModel(getStatisticsUsecase: sl()),
  );

  // Cubit
  sl.registerFactory<StatisticsCubit>(() => StatisticsCubit(viewmodel: sl()));

  sl.registerLazySingleton<FileRepository>(() => FileRepositoryImpl());
  sl.registerLazySingleton(() => GetFilesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteFilesUseCase(sl()));
  
  // Regular file manager (kept for backward compatibility)
  sl.registerLazySingleton(
    () => FileManagerViewModel(getFilesUsecase: sl(), deleteFilesUsecase: sl()),
  );
  sl.registerFactory(() => FileManagerCubit(viewModel: sl()));
  
  // Optimized file manager (used in app routes)
  sl.registerLazySingleton(
    () => OptimizedFileManagerViewModel(
      getFilesUsecase: sl(),
      deleteFilesUsecase: sl(),
      fileRepository: sl(),
    ),
  );
  sl.registerFactory(() => OptimizedFileManagerCubit(sl()));

  // All Categories
  sl.registerLazySingleton(() => AllCategoriesViewModel());

  // Category Details
  sl.registerFactory(() => CategoryDetailsCubit(getFilesUsecase: sl()));

  // Pro Access Feature
  sl.registerLazySingleton<ProAccessRepository>(
    () => ProAccessRepositoryImpl(),
  );

  // Services
  sl.registerLazySingleton(() => ProAccessService(repository: sl()));
  sl.registerLazySingleton(() => FeatureGate(proAccessService: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetProAccessUseCase(repository: sl()));
  sl.registerLazySingleton(() => CheckProFeatureUseCase(repository: sl()));
  sl.registerLazySingleton(() => ValidateProAccessUseCase(repository: sl()));

  // ViewModel
  sl.registerLazySingleton(
    () => ProAccessViewModel(
      proAccessService: sl(),
      featureGate: sl(),
      getProAccessUsecase: sl(),
      checkProFeatureUsecase: sl(),
    ),
  );

  // Cubit
  sl.registerFactory(() => ProAccessCubit(viewModel: sl()));

  // Storage Analysis
  sl.registerLazySingleton(() => AnalyzeStorageUseCase(sl()));
  sl.registerLazySingleton(() => StorageAnalysisViewModel(sl()));
  sl.registerFactory(() => StorageAnalysisCubit(viewModel: sl()));

  // Cleanup Results
  sl.registerLazySingleton(() => CleanupResultsViewModel());
  sl.registerFactory(() => CleanupResultsCubit(viewModel: sl()));
}
