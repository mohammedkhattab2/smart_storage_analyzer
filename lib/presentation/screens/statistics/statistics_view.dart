import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/statistics_content.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/error_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/statistics/statistics_header.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    
    // Add haptic feedback on load
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: BlocBuilder<StatisticsCubit, StatisticsState>(
            builder: (context, state) {
              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.cardBackground,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await context.read<StatisticsCubit>().refresh();
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: const StatisticsHeader(),
                    ),
                    SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        child: _buildContent(context, state),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StatisticsState state) {
    if (state is StatisticsLoading) {
      return Container(
        key: const ValueKey('loading'),
        height: MediaQuery.of(context).size.height * 0.6,
        child: const LoadingWidget(),
      );
    }
    if (state is StatisticsLoaded) {
      return Container(
        key: const ValueKey('loaded'),
        child: StatisticsContent(state: state),
      );
    }
    if (state is StatisticsError) {
      return Container(
        key: const ValueKey('error'),
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
