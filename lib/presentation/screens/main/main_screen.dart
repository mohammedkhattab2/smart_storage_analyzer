import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/presentation/widgets/bottom_navigation/bottom_nav_bar.dart';

class MainScreen extends StatelessWidget {
  final Widget child;
  
  const MainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    // Remove PopScope completely - let Android back button work naturally
    // The app will exit when user presses back on dashboard (root screen)
    // which is the expected Android behavior
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // Use the child widget passed from ShellRoute
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentLocation: currentLocation,
        onItemTapped: (route) => context.go(route),
      ),
    );
  }
}

