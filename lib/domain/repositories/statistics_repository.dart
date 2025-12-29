import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

abstract class StatisticsRepository {
  Future<StorageStatistics> getStatistics(String period);
  List<String> getAvailablePeriods();
}
