import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/presentation/widgets/bottom_navigation/bottom_nav_bar.dart';

class MainScreen extends StatelessWidget {
  final Widget child;
  const MainScreen({
    super.key ,
    required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentLocation: GoRouterState.of(context).matchedLocation,
        onItemTapped: (route)=> context.go(route),
      ),
    );
  }
}
