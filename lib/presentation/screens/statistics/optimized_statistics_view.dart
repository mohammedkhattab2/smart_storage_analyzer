import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/quick_stats_section.dart';
import 'package:smart_storage_analyzer/presentation/widgets/charts/categories_usage_chart.dart';
import 'package:smart_storage_analyzer/presentation/widgets/charts/storage_pie_chart.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/skeleton_loader.dart';

/// Optimized statistics view with skeleton loading and performance improvements
class OptimizedStatisticsView extends StatefulWidget {
  const OptimizedStatisticsView({super.key});

  @override
  State<OptimizedStatisticsView> createState() => _OptimizedStatisticsViewState();
}

class _OptimizedStatisticsViewState extends State<OptimizedStatisticsView> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<StatisticsCubit, StatisticsState>(
          builder: (context, state) {
            if (state is StatisticsLoading || state is StatisticsInitial) {
              return _buildSkeletonLoading(context);
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
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          SkeletonLoader(
            height: 32,
            width: 200,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            height: 20,
            width: 150,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: AppSize.paddingLarge),
          
          // Quick stats skeleton
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  height: 100,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: AppSize.paddingSmall),
              Expanded(
                child: SkeletonLoader(
                  height: 100,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: AppSize.paddingSmall),
              Expanded(
                child: SkeletonLoader(
                  height: 100,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          
          // Chart skeleton
          SkeletonLoader(
            height: 300,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: AppSize.paddingLarge),
          
          // Usage breakdown skeleton
          SkeletonLoader(
            height: 28,
            width: 180,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: AppSize.paddingMedium),
          ...List.generate(5, (index) => 
            Padding(
              padding: const EdgeInsets.only(bottom: AppSize.paddingSmall),
              child: SkeletonLoader(
                height: 72,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, StatisticsLoaded state) {
    final usedStorage = state.statistics.totalSpace - state.statistics.currentFreeSpace;
    final usedStorageGb = usedStorage / (1024 * 1024 * 1024); // Convert bytes to GB
    final freeStorageGb = state.statistics.currentFreeSpace / (1024 * 1024 * 1024);

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger statistics refresh
        context.read<StatisticsCubit>().loadStatistics();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSize.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with fade in animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: _buildHeader(context, state),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSize.paddingLarge),

            // Quick stats with staggered animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: QuickStatsSection(
                      freeSpace: state.statistics.currentFreeSpace.toDouble(),
                      totalSpace: state.statistics.totalSpace.toDouble(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSize.paddingXLarge),

            // Storage pie chart
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: _buildChartSection(
                      context,
                      title: 'Storage Distribution',
                      child: SizedBox(
                        height: 300,
                        child: StoragePieChart(
                          usedSpaceGb: usedStorageGb,
                          freeSpaceGb: freeStorageGb,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSize.paddingLarge),

            // Categories usage chart
            if (state.statistics.categoryBreakdown.isNotEmpty) ...[
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: _buildChartSection(
                        context,
                        title: 'Categories Breakdown',
                        child: SizedBox(
                          height: 250,
                          child: CategoriesUsageChart(
                            categories: state.statistics.categoryBreakdown,
                            totalUsedSpace: usedStorage,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSize.paddingLarge),
            ],

            // Usage breakdown list
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: _buildUsageBreakdown(context, state),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StatisticsLoaded state) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Statistics',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Period: ${state.statistics.period}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha:  0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha:  0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSize.paddingMedium),
          child,
        ],
      ),
    );
  }

  Widget _buildUsageBreakdown(BuildContext context, StatisticsLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate total used space
    final usedStorage = state.statistics.totalSpace - state.statistics.currentFreeSpace;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage Breakdown',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSize.paddingMedium),
        ...state.statistics.categoryBreakdown.map((category) {
          final percentage = usedStorage > 0
              ? (category.sizeInBytes / usedStorage * 100)
              : 0.0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSize.paddingSmall),
            child: Container(
              padding: const EdgeInsets.all(AppSize.paddingMedium),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha:  0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category.name, colorScheme)
                              .withValues(alpha:  0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(category.name),
                          color: _getCategoryColor(category.name, colorScheme),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSize.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${category.fileCount} files',
                              style: theme.textTheme.bodySmall?.copyWith(
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
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSize.paddingSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: _getCategoryColor(category.name, colorScheme),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSize.paddingLarge),
            Text(
              'Failed to load statistics',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            FilledButton.icon(
              onPressed: () {
                context.read<StatisticsCubit>().loadStatistics();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'images':
        return Icons.image;
      case 'videos':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'documents':
        return Icons.description;
      case 'apps':
        return Icons.apps;
      case 'others':
      case 'other':
        return Icons.folder;
      default:
        return Icons.folder;
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
      case 'others':
      case 'other':
        return Colors.grey;
      default:
        return colorScheme.primary;
    }
  }
}