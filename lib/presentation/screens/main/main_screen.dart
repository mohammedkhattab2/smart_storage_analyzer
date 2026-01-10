import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/presentation/widgets/bottom_navigation/bottom_nav_bar.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';

class MainScreen extends StatelessWidget {
  final Widget child;
  
  const MainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    return PopScope(
      canPop: currentLocation == AppRoutes.dashboard, // Can only pop (exit) when on dashboard
      onPopInvoked: (didPop) {
        // If we didn't pop and we're not on dashboard, navigate to dashboard
        if (!didPop && currentLocation != AppRoutes.dashboard) {
          context.go(AppRoutes.dashboard);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        // Use the child widget passed from ShellRoute
        body: child,
        bottomNavigationBar: BottomNavBar(
          currentLocation: currentLocation,
          onItemTapped: (route) => context.go(route),
        ),
      ),
    );
  }
}

