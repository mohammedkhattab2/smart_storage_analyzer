import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/optimized_file_manager_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/main/main_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/settings/settings_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/optimized_statistics_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/storage_analysis/storage_analysis_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/cleanup_results/cleanup_results_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/unused_apps/unused_apps_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/whatsapp_cleaner/whatsapp_overview_screen.dart';
import 'package:smart_storage_analyzer/presentation/cubits/whatsapp_cleaner/whatsapp_cleaner_cubit.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPages {
  AppPages._();

  static final GoRouter router = GoRouter(
    initialLocation:
        AppRoutes.dashboard, // Default, will be overridden by redirect
    redirect: (context, state) async {
      final pref = await SharedPreferences.getInstance();
      final hasSeenOnboarding = pref.getBool("hasSeenOnboarding") ?? false;

      // Initial navigation check
      if (state.matchedLocation == '/') {
        return hasSeenOnboarding ? AppRoutes.dashboard : AppRoutes.onboarding;
      }

      // If user is trying to access onboarding but has already seen it, redirect to dashboard
      if (hasSeenOnboarding && state.matchedLocation == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }

      // If user hasn't seen onboarding and is trying to access other pages, redirect to onboarding
      if (!hasSeenOnboarding && state.matchedLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.onboarding,
        name: "onboarding",
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: OnboardingScreen(),
        ),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return MainScreen(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.dashboard,
            name: "dashboard",
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.fileManager,
            name: "fileManager",
            pageBuilder: (context, state) {
              // Optional initial file category passed via `extra`
              final initialCategory = state.extra is FileCategory
                  ? state.extra as FileCategory
                  : null;

              return NoTransitionPage<void>(
                key: state.pageKey,
                child: OptimizedFileManagerScreen(
                  initialCategory: initialCategory,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.statistics,
            name: "statistics",
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const OptimizedStatisticsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: "settings",
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      // Storage Analysis route (outside shell for full screen)
      GoRoute(
        path: AppRoutes.storageAnalysis,
        name: "storageAnalysis",
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const StorageAnalysisScreen(),
        ),
      ),
      // Cleanup Results route
      GoRoute(
        path: AppRoutes.cleanupResults,
        name: "cleanupResults",
        pageBuilder: (context, state) {
          final results = state.extra as StorageAnalysisResults?;
          if (results == null) {
            // If no results, go back to dashboard
            return MaterialPage<void>(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('No analysis results found')),
              ),
            );
          }
          return MaterialPage<void>(
            key: state.pageKey,
            child: CleanupResultsScreen(results: results),
          );
        },
      ),
      // Unused Apps route
      GoRoute(
        path: AppRoutes.unusedApps,
        name: "unusedApps",
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const UnusedAppsScreen(),
        ),
      ),
      // WhatsApp Cleaner route
      GoRoute(
        path: AppRoutes.whatsappCleaner,
        name: "whatsappCleaner",
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: BlocProvider<WhatsAppCleanerCubit>(
            create: (_) => sl<WhatsAppCleanerCubit>(),
            child: const WhatsAppOverviewScreen(),
          ),
        ),
      ),
    ],

    // error page
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text("page not found", style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text(state.matchedLocation, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: Text("Go Home"),
            ),
          ],
        ),
      ),
    ),
  );
}

// === Navigation Helper Functions ===
extension NavigationHelper on BuildContext {
  void navigateTo(String route) => go(route);
  void navigateToReplace(String route) => go(route);

  void navigateBack() {
    // Use natural navigation - just pop
    pop();
  }

  // navigate with parameters
  void navigateToCategory(String categoryName) {
    go('${AppRoutes.dashboard}/category/$categoryName');
  }
}
