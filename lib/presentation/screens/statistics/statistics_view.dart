import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<StatisticsCubit, StatisticsState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainer,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await context.read<StatisticsCubit>().refresh();
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
    if (state is StatisticsInitial || state is StatisticsLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const LoadingWidget(),
      );
    }
    if (state is StatisticsLoaded) {
      return StatisticsContent(state: state);
    }
    if (state is StatisticsError) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: ErrorT(
          message: state.message,
          onRetry: () {
            HapticFeedback.lightImpact();
            context.read<StatisticsCubit>().loadStatistics();
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
