import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/statistics_content.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/error_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/statistics/statistics_header.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<StatisticsCubit, StatisticsState>(
          builder: (sontext, state) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<StatisticsCubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const StatisticsHeader(),
                    _buildContent(context, state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StatisticsState state) {
    if (state is StatisticsLoading) {
      return const LoadingWidget();
    }
    if (state is StatisticsLoaded) {
      return StatisticsContent(state: state);
    }
    if (state is StatisticsError) {
      return ErrorT(
        message: state.message,
        onRetry: () => context.read<StatisticsCubit>().loadStatistics(),
      );
    }
    return const SizedBox.shrink();
  }
}
