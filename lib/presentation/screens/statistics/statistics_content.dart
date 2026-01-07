import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/quick_stats_section.dart';
import 'package:smart_storage_analyzer/presentation/widgets/charts/storage_pie_chart.dart';
import 'package:smart_storage_analyzer/presentation/widgets/charts/categories_usage_chart.dart';

class StatisticsContent extends StatelessWidget {
  final StatisticsLoaded state;
  const StatisticsContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage Overview Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.1),
                  colorScheme.primaryContainer.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Storage Analytics',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor your storage usage and category distribution',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSize.paddingXLarge),

          // Storage Pie Chart showing current usage
          StoragePieChart(
            usedSpaceGb:
                (state.statistics.totalSpace -
                    state.statistics.currentFreeSpace) /
                (1024 * 1024 * 1024),
            freeSpaceGb:
                state.statistics.currentFreeSpace / (1024 * 1024 * 1024),
          ),

          const SizedBox(height: AppSize.paddingXLarge),

          // Magical Categories Usage Chart - now available from statistics data
          if (state.statistics.categoryBreakdown.isNotEmpty) ...[
            CategoriesUsageChart(
              categories: state.statistics.categoryBreakdown,
              totalUsedSpace:
                  state.statistics.totalSpace -
                  state.statistics.currentFreeSpace,
            ),
            const SizedBox(height: AppSize.paddingXLarge),
          ],

          // Quick Stats Section
          QuickStatsSection(
            freeSpace: state.statistics.currentFreeSpace,
            totalSpace: state.statistics.totalSpace,
          ),

          const SizedBox(height: AppSize.paddingMedium),
        ],
      ),
    );
  }
}
