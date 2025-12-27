import 'package:get_it/get_it.dart';
import 'package:smart_storage_analyzer/data/repositories/storage_repository_impl.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/analyze_storage_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_categories_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_storage_info_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';

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
}
