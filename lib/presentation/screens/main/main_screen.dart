import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/presentation/widgets/bottom_navigation/bottom_nav_bar.dart';

class MainScreen extends StatelessWidget {
  final Widget child;
  const MainScreen({
    super.key ,
    required this.child});

  @override
  Widget build(BuildContext context) {
    // Using theme's surface color instead of hardcoded background
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentLocation: GoRouterState.of(context).matchedLocation,
        onItemTapped: (route)=> context.go(route),
      ),
    );
  }
}
