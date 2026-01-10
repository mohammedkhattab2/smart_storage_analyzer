import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/core/services/permission_manager.dart';
import 'package:smart_storage_analyzer/core/theme/app_theme.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_state.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/optimized_file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_cubit.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/optimized_file_manager_viewmodel.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/delete_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/presentation/cubits/storage_analysis/storage_analysis_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/splash/magical_splash_screen.dart';
import 'package:smart_storage_analyzer/routes/app_pages.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Keep native splash while we prepare
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await setupServiceLocator();
  await _setupSystemUi();
  
  // Initialize permission manager
  await PermissionManager().initialize();

  runApp(const MyApp());
}

Future<void> _setupSystemUi() async {
  // Initial system UI setup - will be updated based on theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Remove native splash as we'll show our custom splash
    FlutterNativeSplash.remove();
    
    // Show custom splash for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const MaterialApp(
        home: MagicalSplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => sl<ThemeCubit>()..loadTheme(),
        ),
        BlocProvider<StatisticsCubit>(
          create: (_) => sl<StatisticsCubit>(),
          lazy: false,
        ),
        BlocProvider<DashboardCubit>(
          create: (_) => sl<DashboardCubit>(),
          lazy: false,
        ),
        BlocProvider<OptimizedFileManagerCubit>(
          create: (_) {
            final viewModel = OptimizedFileManagerViewModel(
              getFilesUsecase: sl<GetFilesUseCase>(),
              deleteFilesUsecase: sl<DeleteFilesUseCase>(),
              fileRepository: sl<FileRepository>(),
            );
            return OptimizedFileManagerCubit(viewModel);
          },
          lazy: false,
        ),
        BlocProvider<StorageAnalysisCubit>(
          create: (_) => sl<StorageAnalysisCubit>(),
          lazy: true, // Only create when needed
        ),
        // Add CategoryDetailsCubit as a global singleton to maintain state
        BlocProvider<CategoryDetailsCubit>(
          create: (_) => sl<CategoryDetailsCubit>(),
          lazy: true, // Create when first accessed
        ),
        // Add SettingsCubit as a global singleton to maintain state
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>()..loadSettings(),
          lazy: false, // Load settings early for theme and notifications
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          // Update system UI based on theme
          _updateSystemUiOverlay(context, state);

          return MaterialApp.router(
            title: "Smart Storage Analyzer",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode.themeMode,
            routerConfig: AppPages.router,
            builder: (context, child) {
              // Add fade transition when switching from splash
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateSystemUiOverlay(BuildContext context, ThemeState state) {
    // Get the actual brightness to set system overlay appropriately
    final isDark = context.read<ThemeCubit>().isDarkMode(context);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}
