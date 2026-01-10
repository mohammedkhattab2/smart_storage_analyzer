import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/themed_statistics_view.dart';

/// Optimized statistics screen with beautiful themed design
class OptimizedStatisticsScreen extends StatefulWidget {
  const OptimizedStatisticsScreen({super.key});

  @override
  State<OptimizedStatisticsScreen> createState() => _OptimizedStatisticsScreenState();
}

class _OptimizedStatisticsScreenState extends State<OptimizedStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Load statistics only if not already loaded
    final statisticsCubit = context.read<StatisticsCubit>();
    if (statisticsCubit.state is! StatisticsLoaded) {
      statisticsCubit.loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ThemedStatisticsView();
  }
}