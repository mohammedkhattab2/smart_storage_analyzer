import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/error_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/dashboard_content.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/dashboard_header.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with WidgetsBindingObserver {
  bool _isCheckingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes (user returns from settings)
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      _checkPermissionAndReload();
    }
  }

  Future<void> _checkPermissionAndReload() async {
    if (_isCheckingPermission) return;
    
    _isCheckingPermission = true;
    
    // Check if permission is now granted
    final status = await Permission.storage.status;
    if (status.isGranted && mounted) {
      // Get current state
      final currentState = context.read<DashboardCubit>().state;
      
      // Only reload if we're in error state (permission was denied before)
      if (currentState is DashboardError && 
          currentState.message.toLowerCase().contains('permission')) {
        context.read<DashboardCubit>().loadDashboardData();
      }
    }
    
    _isCheckingPermission = false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSize.paddingSmall),
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () => context.read<DashboardCubit>().refresh(),
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainer,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const DashboardHeader(),
                      _buildContent(context, state),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardState state) {
    if (state is DashboardLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSize.paddingXLarge * 2),
        child: LoadingWidget(),
      );
    }
    if (state is dashboardLoaded) {
      return DashboardContent(state: state);
    }
    if (state is DashboardAnalyzing) {
      // Show content with overlay if we have previous data
      if (state.storageInfo != null && state.categories != null) {
        return Stack(
          children: [
            DashboardContent(
              state: dashboardLoaded(
                storageInfo: state.storageInfo!,
                categories: state.categories!,
              ),
            ),
            _buildAnalyzingOverlay(state),
          ],
        );
      } else {
        // Show analyzing without previous content
        return _buildAnalyzingWidget(state);
      }
    }
    if (state is DashboardError) {
      // Check if error is due to permission
      if (state.message.toLowerCase().contains('permission')) {
        return _buildPermissionError(context);
      }
      return Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: ErrorT(
          message: state.message,
          onRetry: () => context.read<DashboardCubit>().loadDashboardData(),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAnalyzingOverlay(DashboardAnalyzing state) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.surface.withOpacity(0.9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSize.paddingXLarge),
          margin: const EdgeInsets.all(AppSize.paddingLarge),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSize.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              Text(
                state.message,
                style: TextStyle(
                  fontSize: AppSize.fontLarge,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (state.progress != null) ...[
                const SizedBox(height: AppSize.paddingMedium),
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingWidget(DashboardAnalyzing state) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(top: AppSize.paddingXLarge * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: AppSize.paddingLarge),
          Text(
            state.message,
            style: TextStyle(
              fontSize: AppSize.fontLarge,
              color: colorScheme.onSurface,
            ),
          ),
          if (state.progress != null) ...[
            const SizedBox(height: AppSize.paddingMedium),
            Container(
              width: 200,
              child: LinearProgressIndicator(
                value: state.progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPermissionError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(AppSize.paddingXLarge),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSize.paddingLarge),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_off_outlined,
                size: 64,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            Text(
              'Storage Permission Required',
              style: TextStyle(
                fontSize: AppSize.fontXXLarge,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              'To analyze your device storage and show file categories,\nwe need access to your storage.',
              style: TextStyle(
                fontSize: AppSize.fontLarge,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            ElevatedButton.icon(
              onPressed: () async {
                // First try to request permission again
                final status = await Permission.storage.request();
                
                if (status.isPermanentlyDenied) {
                  // Open app settings if permission is permanently denied
                  await openAppSettings();
                  // Note: The app will auto-reload when user returns
                } else if (status.isGranted) {
                  // Reload dashboard if permission granted
                  if (mounted) {
                    context.read<DashboardCubit>().loadDashboardData();
                  }
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              'The app will reload automatically after granting permission',
              style: TextStyle(
                fontSize: AppSize.fontSmall,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
