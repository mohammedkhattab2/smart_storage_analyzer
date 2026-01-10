import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui;
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_state.dart';
import 'package:smart_storage_analyzer/presentation/widgets/charts/enhanced_storage_distribution_chart.dart';

/// Themed Statistics View matching app design language
class ThemedStatisticsView extends StatefulWidget {
  const ThemedStatisticsView({super.key});

  @override
  State<ThemedStatisticsView> createState() => _ThemedStatisticsViewState();
}

class _ThemedStatisticsViewState extends State<ThemedStatisticsView>
    with TickerProviderStateMixin {
  // Animation controllers - light and minimal
  late AnimationController _entranceController;
  late AnimationController _glowController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Entrance animation - one time only
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Subtle glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start entrance animation
    _entranceController.forward();
  }
  
  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
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
            // Magical background orbs (static with subtle glow)
            RepaintBoundary(
              child: _buildMagicalBackground(context),
            ),
            
            // Main content
            SafeArea(
              child: BlocBuilder<StatisticsCubit, StatisticsState>(
                builder: (context, state) {
                  if (state is StatisticsLoading || state is StatisticsInitial) {
                    return _buildLoadingState(context);
                  }

                  if (state is StatisticsError) {
                    return _buildErrorState(context, state.message);
                  }

                  if (state is StatisticsLoaded) {
                    return _buildLoadedContent(context, state);
                  }

                  return const SizedBox.shrink();
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
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return CustomPaint(
          painter: _MagicalOrbsPainter(
            primaryColor: colorScheme.primary,
            secondaryColor: colorScheme.secondary,
            tertiaryColor: colorScheme.tertiary,
            glowIntensity: _glowController.value,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }

  Widget _buildLoadedContent(BuildContext context, StatisticsLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final usedStorage = (state.statistics.totalSpace - state.statistics.currentFreeSpace).toInt();
    final usedPercentage = state.statistics.totalSpace > 0
        ? (usedStorage / state.statistics.totalSpace * 100)
        : 0.0;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        context.read<StatisticsCubit>().loadStatistics();
      },
      color: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainer,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 24),
                
                // Main storage overview with glass effect
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingMedium),
                  child: _buildStorageOverviewCard(context, state, usedStorage, usedPercentage),
                ),
                const SizedBox(height: 24),
                
                // Enhanced storage distribution chart
                EnhancedStorageDistributionChart(
                  totalSpace: state.statistics.totalSpace.toDouble(),
                  freeSpace: state.statistics.currentFreeSpace.toDouble(),
                  categories: state.statistics.categoryBreakdown,
                ),
                const SizedBox(height: 24),
                
                // Quick stats cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingMedium),
                  child: _buildQuickStats(context, state),
                ),
                const SizedBox(height: 24),
                
                // Category breakdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingMedium),
                  child: _buildCategoryBreakdown(context, state, usedStorage),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Storage Statistics',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'Analyze your storage usage',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageOverviewCard(
    BuildContext context,
    StatisticsLoaded state,
    int usedStorage,
    double usedPercentage,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final totalGb = state.statistics.totalSpace / (1024 * 1024 * 1024);
    final usedGb = usedStorage / (1024 * 1024 * 1024);
    final freeGb = state.statistics.currentFreeSpace / (1024 * 1024 * 1024);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: isDark ? 0.9 : 0.95),
            colorScheme.surface.withValues(alpha: isDark ? 0.8 : 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          width: 1,
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Circular progress with gradient
              SizedBox(
                width: 200,
                height: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: usedPercentage / 100),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          ),
                        ),
                        // Progress circle
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 16,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(value * 100, colorScheme),
                            ),
                          ),
                        ),
                        // Center content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                              ).createShader(bounds),
                              child: Text(
                                '${(value * 100).round()}%',
                                style: textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              'Used Space',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              // Storage details with gradient background
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.05),
                      colorScheme.secondary.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStorageDetailItem(
                      context,
                      'Total',
                      '${totalGb.toStringAsFixed(1)} GB',
                      Icons.storage_rounded,
                      colorScheme.primary,
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    _buildStorageDetailItem(
                      context,
                      'Used',
                      '${usedGb.toStringAsFixed(1)} GB',
                      Icons.folder_rounded,
                      colorScheme.secondary,
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    _buildStorageDetailItem(
                      context,
                      'Free',
                      '${freeGb.toStringAsFixed(1)} GB',
                      Icons.cloud_outlined,
                      colorScheme.tertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, StatisticsLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Calculate total file count from categories
    int totalFileCount = 0;
    for (var category in state.statistics.categoryBreakdown) {
      totalFileCount += category.fileCount;
    }
    
    // Calculate used storage and average file size
    final usedStorage = state.statistics.totalSpace - state.statistics.currentFreeSpace;
    final avgFileSize = totalFileCount > 0 ? usedStorage / totalFileCount : 0;
    
    // Find largest category
    final largestCategory = state.statistics.categoryBreakdown.isNotEmpty
        ? state.statistics.categoryBreakdown.reduce((a, b) => 
            a.sizeInBytes > b.sizeInBytes ? a : b).name
        : 'None';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Files',
            totalFileCount.toString(),
            Icons.file_copy_rounded,
            colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Avg Size',
            avgFileSize > 0 
                ? SizeFormatter.formatBytes(avgFileSize.toInt())
                : '0 B',
            Icons.straighten_rounded,
            colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Largest',
            largestCategory,
            Icons.folder_special_rounded,
            colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context,
    StatisticsLoaded state,
    int usedStorage,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.category_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Storage Breakdown',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...state.statistics.categoryBreakdown.map((category) {
          final percentage = usedStorage > 0
              ? (category.sizeInBytes / usedStorage * 100)
              : 0.0;
          
          return TweenAnimationBuilder<double>(
            key: ValueKey(category.name),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (state.statistics.categoryBreakdown.indexOf(category) * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildCategoryCard(context, category, percentage),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    dynamic category,
    double percentage,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categoryColor = _getCategoryColor(category.name, colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor,
                      categoryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(category.name),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${category.fileCount} files',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    SizeFormatter.formatBytes(category.sizeInBytes.toInt()),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: categoryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.errorContainer,
                    colorScheme.errorContainer.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.read<StatisticsCubit>().loadStatistics();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage, ColorScheme colorScheme) {
    if (percentage >= 90) return Colors.red;
    if (percentage >= 75) return Colors.orange;
    if (percentage >= 50) return colorScheme.primary;
    return Colors.green;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'images':
        return Icons.image_rounded;
      case 'videos':
        return Icons.video_library_rounded;
      case 'audio':
        return Icons.library_music_rounded;
      case 'documents':
        return Icons.description_rounded;
      case 'apps':
        return Icons.apps_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  Color _getCategoryColor(String category, ColorScheme colorScheme) {
    switch (category.toLowerCase()) {
      case 'images':
        return Colors.blue;
      case 'videos':
        return Colors.red;
      case 'audio':
        return Colors.orange;
      case 'documents':
        return colorScheme.primary;
      case 'apps':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// Magical orbs painter - optimized for performance
class _MagicalOrbsPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final double glowIntensity;

  _MagicalOrbsPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal, 
        30 + (glowIntensity * 10),
      );

    // Top left orb
    paint.shader = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.05 + (glowIntensity * 0.03)),
        primaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(
      center: const Offset(0, 0), 
      radius: 150,
    ));
    canvas.drawCircle(const Offset(0, 0), 150, paint);

    // Bottom right orb
    paint.shader = RadialGradient(
      colors: [
        secondaryColor.withValues(alpha: 0.04 + (glowIntensity * 0.02)),
        secondaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width, size.height),
      radius: 200,
    ));
    canvas.drawCircle(Offset(size.width, size.height), 200, paint);

    // Center accent
    paint.shader = RadialGradient(
      colors: [
        tertiaryColor.withValues(alpha: 0.03 + (glowIntensity * 0.02)),
        tertiaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.7, size.height * 0.3),
      radius: 120,
    ));
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 120, paint);
  }

  @override
  bool shouldRepaint(covariant _MagicalOrbsPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity;
  }
}