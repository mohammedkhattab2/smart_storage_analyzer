import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/quick_stats_section.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/storage_chart_widget.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/storage_history_section.dart';

class StatisticsContent extends StatelessWidget {
  final StatisticsLoaded state;
  const StatisticsContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StorageHistorySection(
            currentPeriod: state.statistics.period,
            availablePeriods: state.availablePeriods,
            onPeriodChanged: (period) {
              context.read<StatisticsCubit>().changePeriod(period!);
            },
          ),
          const SizedBox(height: AppSize.paddingMedium),
          StorageChartWidget(
            dataPoints: state.statistics.dataPoint,
            period: state.statistics.period,
          ),
          const SizedBox(height: AppSize.paddingLarge),
          QuickStatsSection(
            freeSpace: state.statistics.currentFreeSpace,
            totalSpace: state.statistics.totalSpace,
          ),
        ],
      ),
    );
  }
}
