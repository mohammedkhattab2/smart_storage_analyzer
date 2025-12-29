import 'package:smart_storage_analyzer/domain/entities/statistics.dart';
import 'package:smart_storage_analyzer/domain/repositories/statistics_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_statistics_usecase.dart';

class StatisticsViewmodel {
  final GetStatisticsUsecase getStatisticsUsecase;
  final StatisticsRepository statisticsRepository;
  StatisticsViewmodel({
    required this.getStatisticsUsecase,
    required this.statisticsRepository,
  });

  List<String> getAvailablePeriods() {
    return statisticsRepository.getAvailablePeriods();
  }

  Future<StorageStatistics> getStatistics(String period) async {
    try {
      return await getStatisticsUsecase.excute(period);
    } catch (e) {
      print('Error getting statistics in ViewModel: $e');
      rethrow;
    }
  }
}
