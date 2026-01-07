import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/core/services/permission_manager.dart';
import 'package:smart_storage_analyzer/core/theme/app_theme.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_state.dart';
import 'package:smart_storage_analyzer/routes/app_pages.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await setupServiceLocator();
  await _setupSystemUi();
  
  // Initialize permission manager
  await PermissionManager().initialize();

  runApp(const MyApp());

  // Remove splash screen after app is loaded
  FlutterNativeSplash.remove();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ThemeCubit>()..loadTheme(),
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
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
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
