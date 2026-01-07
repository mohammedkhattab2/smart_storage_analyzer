import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/statistics_viewmodel.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  final StatisticsViewModel viewmodel;
  StatisticsCubit({required this.viewmodel}) : super(StatisticsInitial());

  Future<void> loadStatistics({String period = "This Week"}) async {
    emit(StatisticsLoading());
    try {
      final statistics = await viewmodel.getStatistics(period);
      final periods = viewmodel.getAvailablePeriods();
      emit(StatisticsLoaded(statistics: statistics, availablePeriods: periods));
      Logger.info('Statistics loaded successfully for period: $period');
    } catch (e) {
      Logger.error('Error loading statistics', e);

      // Handle specific error cases
      String errorMessage = 'Failed to load statistics';
      if (e.toString().contains('NO_STORAGE_INFO')) {
        errorMessage =
            'Unable to access storage information. Please check app permissions.';
      }

      emit(StatisticsError(errorMessage));
    }
  }

  void changePeriod(String period) {
    loadStatistics(period: period);
  }

  Future<void> refresh() async {
    if (state is StatisticsLoaded) {
      final currentPeriod = (state as StatisticsLoaded).statistics.period;
      await loadStatistics(period: currentPeriod);
    } else {
      await loadStatistics();
    }
  }
}
