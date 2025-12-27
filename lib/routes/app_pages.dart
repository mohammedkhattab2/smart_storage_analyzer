import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/presentation/screens/category_details/category_details_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_details/file_details_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/file_manager_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/main/main_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/settings/settings_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/statistics_screen.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPages {
  AppPages._();

  static Future<String> _getInitialLocation() async {
    final pref = await SharedPreferences.getInstance();
    final hasSeenOnboarding = pref.getBool("hasSeenOnboarding") ?? false;
    return hasSeenOnboarding ? AppRoutes.dashboard : AppRoutes.onboarding;
  }

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.dashboard, // Default, will be overridden by redirect
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
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
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
            routes: <RouteBase>[
              GoRoute(
                path: "category/:name",
                name: "categoryDetails",
                builder: (context, state) {
                  final categoryName = state.pathParameters["name"]!;
                  return CategoryDetailsScreen(category: categoryName);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.fileManager,
            name: "fileManager",
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: FileManagerScreen(),
            ),
            routes: <RouteBase>[
              GoRoute(
                path: "details",
                name: "fileDetails",
                builder: (context, state) {
                  return FileDetailsScreen();
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.statistics,
            name: "statistics",
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: StatisticsScreen(),
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
    if (canPop()) {
      pop();
    } else {
      go(AppRoutes.dashboard);
    }
  }
  // navigate with parameters 
  void navigateToCategory(String categoryName) {
    go('${AppRoutes.dashboard}/category/$categoryName');
  }
}
