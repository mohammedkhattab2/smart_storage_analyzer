import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/services/permission_service.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/dashboard_content.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/skeleton_loader.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';
import 'package:smart_storage_analyzer/data/repositories/storage_repository_impl.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isCheckingPermission = false;
  final _permissionService = PermissionService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Clear category cache to ensure fresh data
    _clearCategoryCache();
    
    // Initialize animation controller for smooth transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    // Force refresh after clearing cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardCubit>().refresh(context: context);
      }
    });
  }
  
  void _clearCategoryCache() {
    try {
      // Access the storage repository to clear cache
      final storageRepo = sl<StorageRepository>() as StorageRepositoryImpl;
      storageRepo.clearCategoriesCache();
    } catch (e) {
      // Ignore errors - cache clearing is not critical
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
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

    // Check if permission is now granted using the centralized service
    final hasPermission = await _permissionService.hasStoragePermission();
    if (hasPermission && mounted) {
      // Get current state
      final currentState = context.read<DashboardCubit>().state;

      // Only reload if we're in error state (permission was denied before)
      if (currentState is DashboardError &&
          currentState.message.toLowerCase().contains('permission')) {
        context.read<DashboardCubit>().loadDashboardData(context: context);
      }
    }

    _isCheckingPermission = false;
  }

  Future<void> _handlePermissionRequest() async {
    // The dashboard cubit will handle the permission request with the new PermissionService
    if (mounted) {
      context.read<DashboardCubit>().loadDashboardData(context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha: 0.02),
              colorScheme.secondary.withValues(alpha: 0.03),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Magical background orbs
            // Optimize background with repaint boundary
            RepaintBoundary(
              child: _buildMagicalBackground(context),
            ),

            SafeArea(
              child: BlocBuilder<DashboardCubit, DashboardState>(
                // Only rebuild when state actually changes
                buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      await context.read<DashboardCubit>().refresh(
                        context: context,
                      );
                    },
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainer,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSize.paddingSmall),
                          const RepaintBoundary(
                            child: DashboardHeader(),
                          ),
                          AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildContent(context, state),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMagicalBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use CustomPaint for better performance
    return CustomPaint(
      painter: _BackgroundPainter(
        primaryColor: colorScheme.primary,
        secondaryColor: colorScheme.secondary,
        tertiaryColor: colorScheme.tertiary,
      ),
      size: MediaQuery.of(context).size,
    );
  }

  Widget _buildContent(BuildContext context, DashboardState state) {
    if (state is DashboardLoading) {
      return Padding(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.only(top: AppSize.paddingXLarge * 2),
        child: _buildMagicalLoadingWidget(),
      );
    }
    if (state is DashboardLoaded) {
      return DashboardContent(key: const ValueKey('loaded'), state: state);
    }
    if (state is DashboardAnalyzing) {
      // Show content with overlay if we have previous data
      if (state.storageInfo != null && state.categories != null) {
        return Stack(
          children: [
            DashboardContent(
              state: DashboardLoaded(
                storageInfo: state.storageInfo!,
                categories: state.categories!,
              ),
            ),
            _buildMagicalAnalyzingOverlay(state),
          ],
        );
      } else {
        // Show analyzing without previous content
        return _buildMagicalAnalyzingWidget(state);
      }
    }
    if (state is DashboardError) {
      // Check if error is due to permission
      if (state.message.toLowerCase().contains('permission')) {
        return _buildMagicalPermissionError(context);
      }
      return Padding(
        key: const ValueKey('error'),
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: _buildMagicalErrorWidget(
          message: state.message,
          onRetry: () => context.read<DashboardCubit>().loadDashboardData(
            context: context,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMagicalLoadingWidget() {
    return const Padding(
      padding: EdgeInsets.all(AppSize.paddingLarge),
      child: _LoadingSkeletonWidget(),
    );
  }

  Widget _buildMagicalAnalyzingOverlay(DashboardAnalyzing state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [
            colorScheme.surface.withValues(alpha: 0.95),
            colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSize.paddingXLarge * 1.5),
          margin: const EdgeInsets.all(AppSize.paddingLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainer,
                colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              Text(
                state.message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (state.progress != null) ...[
                const SizedBox(height: AppSize.paddingLarge),
                Container(
                  width: 200,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value: state.progress,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSize.paddingSmall),
                Text(
                  '${(state.progress! * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalAnalyzingWidget(DashboardAnalyzing state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSize.paddingXLarge * 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
                Icon(
                  Icons.analytics_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          Text(
            state.message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.progress != null) ...[
            const SizedBox(height: AppSize.paddingLarge),
            _buildMagicalProgressBar(state.progress!),
          ],
        ],
      ),
    );
  }

  Widget _buildMagicalProgressBar(double progress) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 250,
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
              ),
            ),
            if (progress > 0)
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMagicalPermissionError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSize.paddingXLarge),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.errorContainer.withValues(alpha: 0.8),
                    colorScheme.errorContainer.withValues(alpha: 0.3),
                    colorScheme.errorContainer.withValues(alpha: 0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.error.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.errorContainer,
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.folder_off_outlined,
                      size: 64,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  colorScheme.error,
                  colorScheme.error.withValues(alpha: 0.8),
                ],
              ).createShader(bounds),
              child: Text(
                'Storage Permission Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppSize.paddingLarge),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'To analyze your device storage and show file categories,\nwe need access to your storage.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge * 1.5),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handlePermissionRequest,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingXLarge,
                      vertical: AppSize.paddingMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings, color: colorScheme.onPrimary),
                        const SizedBox(width: AppSize.paddingSmall),
                        Text(
                          'Grant Permission',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.paddingLarge,
                vertical: AppSize.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSize.paddingSmall),
                  Text(
                    'Auto-reload after granting permission',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMagicalErrorWidget({
    required String message,
    required VoidCallback onRetry,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSize.paddingLarge),
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.errorContainer.withValues(alpha: 0.3),
              colorScheme.errorContainer.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.error.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: AppSize.paddingLarge),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSize.paddingLarge,
                  vertical: AppSize.paddingMedium,
                ),
                backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized background painter for better performance
class _BackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  _BackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    // Top left orb
    paint.shader = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.08),
        primaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: const Offset(-100, -100), radius: 150));
    canvas.drawCircle(const Offset(-100, -100), 150, paint);

    // Bottom right orb
    paint.shader = RadialGradient(
      colors: [
        secondaryColor.withValues(alpha: 0.06),
        secondaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width + 150, size.height + 150),
      radius: 200,
    ));
    canvas.drawCircle(Offset(size.width + 150, size.height + 150), 200, paint);

    // Center glow
    paint.shader = RadialGradient(
      colors: [
        tertiaryColor.withValues(alpha: 0.05),
        tertiaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.3),
      radius: 100,
    ));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.3), 100, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Optimized loading skeleton widget
class _LoadingSkeletonWidget extends StatelessWidget {
  const _LoadingSkeletonWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Storage circle skeleton
        const Center(
          child: SkeletonLoader(
            width: 240,
            height: 240,
            borderRadius: BorderRadius.all(Radius.circular(120)),
          ),
        ),
        const SizedBox(height: AppSize.paddingXLarge),
        // Details section skeleton
        const SkeletonLoader(
          height: 20,
          width: 150,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          margin: EdgeInsets.only(bottom: AppSize.paddingMedium),
        ),
        Row(
          children: const [
            Expanded(
              child: SkeletonLoader(
                height: 60,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            SizedBox(width: AppSize.paddingMedium),
            Expanded(
              child: SkeletonLoader(
                height: 60,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSize.paddingXLarge),
        // Categories section skeleton
        const SkeletonLoader(
          height: 20,
          width: 120,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          margin: EdgeInsets.only(bottom: AppSize.paddingMedium),
        ),
        const SkeletonGridLoader(
          itemCount: 6,
          crossAxisCount: 2,
          padding: EdgeInsets.zero,
          childAspectRatio: 1.3,
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
