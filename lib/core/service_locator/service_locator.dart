import 'package:get_it/get_it.dart';
import 'package:smart_storage_analyzer/data/repositories/settings_repository_impl.dart';
import 'package:smart_storage_analyzer/data/repositories/statistics_repository_impl.dart';
import 'package:smart_storage_analyzer/data/repositories/storage_repository_impl.dart';
import 'package:smart_storage_analyzer/domain/repositories/settings_repository.dart';
import 'package:smart_storage_analyzer/domain/repositories/statistics_repository.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/analyze_storage_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_categories_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_settings_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_statistics_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_storage_info_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/sign_out_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/update_settings_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_cubit.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/statistics_viewmodel.dart';

final GetIt sl = GetIt.instance;
Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<StorageRepository>(() => StorageRepositoryImpl());
  sl.registerLazySingleton(() => GetCategoriesUsecase(sl()));
  sl.registerLazySingleton(() => GetStorageInfoUsecase(sl()));
  sl.registerLazySingleton(() => AnalyzeStorageUsecase(sl()));
  sl.registerFactory(
    () => DashboardCubit(
      getStorageInfoUsecase: sl(),
      getCategoriesUsecase: sl(),
      analyzeStorageUsecase: sl(),
    ),
  );
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  sl.registerLazySingleton(() => GetSettingsUsecase(sl()));
  sl.registerLazySingleton(() => UpdateSettingsUsecase(sl()));
  sl.registerLazySingleton(() => SignOutUsecase(sl()));
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
    () => StatisticsRepositoryImpl(),
  );

  // UseCase
  sl.registerLazySingleton<GetStatisticsUsecase>(
    () => GetStatisticsUsecase(sl()),
  );

  // ViewModel
  sl.registerLazySingleton<StatisticsViewmodel>(
    () => StatisticsViewmodel(
      getStatisticsUsecase: sl(),
      statisticsRepository: sl(),
    ),
  );

  // Cubit
  sl.registerFactory<StatisticsCubit>(
    () => StatisticsCubit(viewmodel: sl()),
  );


}
