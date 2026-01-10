import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/dashboard/dashboard_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    // Load dashboard data only if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dashboardCubit = context.read<DashboardCubit>();
        // Use the new hasLoadedData flag to prevent unnecessary reloads
        if (!dashboardCubit.hasLoadedData) {
          // Don't auto-request permission on initial load
          dashboardCubit.loadDashboardData(
            context: context,
            autoRequestPermission: false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return const DashboardView();
  }
}
