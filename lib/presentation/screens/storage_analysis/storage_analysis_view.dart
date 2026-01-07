import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/presentation/cubits/storage_analysis/storage_analysis_cubit.dart';

class StorageAnalysisView extends StatefulWidget {
  const StorageAnalysisView({super.key});

  @override
  State<StorageAnalysisView> createState() => _StorageAnalysisViewState();
}

class _StorageAnalysisViewState extends State<StorageAnalysisView>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  
  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Cache gradient decoration
    final backgroundDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.surface,
          colorScheme.primary.withValues(alpha: 0.03),
          colorScheme.secondary.withValues(alpha: 0.05),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: backgroundDecoration,
        child: SafeArea(
          child: BlocBuilder<StorageAnalysisCubit, StorageAnalysisState>(
            builder: (context, state) {
              if (state is StorageAnalysisInProgress) {
                return _buildMagicalProgressView(
                  context,
                  state,
                  _scanAnimationController,
                );
              }

              // Default state
              return Center(child: _buildGlowingLoader(context));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalProgressView(
    BuildContext context,
    StorageAnalysisInProgress state,
    AnimationController scanAnimation,
  ) {
    return Stack(
      children: [
        // Background pattern - wrapped with RepaintBoundary
        RepaintBoundary(
          child: _buildBackgroundPattern(context),
        ),

        // Main content
        Column(
          children: [
            // Custom app bar
            _buildCustomAppBar(context),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppSize.paddingXLarge),

                    // Magical scanner visualization
                    _buildScannerVisualization(
                      context,
                      state,
                      scanAnimation,
                    ),

                    const SizedBox(height: AppSize.paddingXLarge * 2),

                    // Progress info section
                    _buildProgressInfo(context, state),

                    const SizedBox(height: AppSize.paddingXLarge * 2),

                    // Stats cards
                    _buildStatsCards(context, state),

                    const SizedBox(height: AppSize.paddingXLarge * 2),

                    // Action section
                    _buildActionSection(context),

                    const SizedBox(height: AppSize.paddingXLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundPattern(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: CustomPaint(
        painter: _OptimizedMagicalBackgroundPainter(
          primaryColor: colorScheme.primary.withValues(alpha: 0.05),
          secondaryColor: colorScheme.secondary.withValues(alpha: 0.03),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<StorageAnalysisCubit>().cancelAnalysis();
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: Text(
              'Deep Storage Analysis',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerVisualization(
    BuildContext context,
    StorageAnalysisInProgress state,
    AnimationController scanAnimation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Container(
        width: 240,
        height: 240,
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
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CircularProgressIndicator(
                value: state.progress,
                strokeWidth: 8,
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),

            // Middle ring with animated gradient
            RotationTransition(
              turns: scanAnimation,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.0),
                      colorScheme.primary.withValues(alpha: 0.3),
                      colorScheme.secondary.withValues(alpha: 0.3),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),

          // Inner circle with icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_rounded, size: 48, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  '${(state.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
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

  Widget _buildProgressInfo(
    BuildContext context,
    StorageAnalysisInProgress state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingLarge),
      child: Column(
        children: [
          // Current operation
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSize.paddingLarge,
              vertical: AppSize.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSize.radiusLarge),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSize.paddingSmall),
                Text(
                  state.message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSize.paddingLarge),

          // Progress bar with gradient
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: state.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                      ),
                    ),
                  ),
                  // Shimmer effect
                  if (state.progress > 0)
                    FractionallySizedBox(
                      widthFactor: state.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.4, 0.5, 0.6],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    StorageAnalysisInProgress state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate estimated values based on progress
    final filesScanned = (state.progress * 15000).toInt();
    final spaceAnalyzed = (state.progress * 50).toStringAsFixed(1);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingLarge),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.folder_open,
                label: 'Files Scanned',
                value: filesScanned.toString(),
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSize.paddingMedium),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.storage,
                label: 'Space Analyzed',
                value: '${spaceAnalyzed}GB',
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(AppSize.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: AppSize.paddingSmall),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Cancel button with gradient border
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.error.withValues(alpha: 0.5),
                colorScheme.error.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSize.radiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSize.radiusLarge - 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<StorageAnalysisCubit>().cancelAnalysis();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(AppSize.radiusLarge - 2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingXLarge,
                      vertical: AppSize.paddingMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 20, color: colorScheme.error),
                        const SizedBox(width: AppSize.paddingSmall),
                        Text(
                          'Cancel Analysis',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSize.paddingMedium),

        // Info text with subtle background
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSize.paddingXLarge),
          padding: const EdgeInsets.all(AppSize.paddingMedium),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSize.radiusMedium),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSize.paddingSmall),
              Flexible(
                child: Text(
                  'Deep analysis in progress. This may take a few moments.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlowingLoader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircularProgressIndicator(
        strokeWidth: 4,
        color: colorScheme.primary,
      ),
    );
  }
}

// Optimized custom painter for magical background
class _OptimizedMagicalBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _OptimizedMagicalBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    // Draw subtle circles with blur for softer effect
    paint.color = primaryColor;
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.1),
      80,
      paint,
    );

    paint.color = secondaryColor;
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      100,
      paint,
    );

    paint.color = primaryColor.withValues(alpha: 0.03);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.7),
      90,
      paint,
    );
  }

  @override
  bool shouldRepaint(_OptimizedMagicalBackgroundPainter oldDelegate) =>
    oldDelegate.primaryColor != primaryColor ||
    oldDelegate.secondaryColor != secondaryColor;
}
