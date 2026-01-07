import 'package:smart_storage_analyzer/domain/entities/statistics.dart';
import 'package:smart_storage_analyzer/domain/repositories/statistics_repository.dart';

class GetStatisticsUseCase {
  final StatisticsRepository repository;

  GetStatisticsUseCase(this.repository);
  Future<StorageStatistics> excute(String period) async {
    return await repository.getStatistics(period);
  }
}
