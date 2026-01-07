import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class StorageDataPointModel extends StorageDataPoint {
  const StorageDataPointModel({
    required super.date,
    required super.usedSpace,
    required super.freeSpace,
  });

  factory StorageDataPointModel.fromJson(Map<String, dynamic> json) {
    return StorageDataPointModel(
      date: DateTime.parse(json['date']),
      usedSpace: (json['usedSpace'] as num).toDouble(),
      freeSpace: (json['freeSpace'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'usedSpace': usedSpace,
      'freeSpace': freeSpace,
    };
  }
}

class StorageStatisticsModel extends StorageStatistics {
  const StorageStatisticsModel({
    required super.dataPoints,
    required super.currentFreeSpace,
    required super.totalSpace,
    required super.period,
    required super.categoryBreakdown,
  });

  factory StorageStatisticsModel.fromJson(Map<String, dynamic> json) {
    // For now, return empty categories list since we don't have the data
    return StorageStatisticsModel(
      dataPoints: (json['dataPoints'] as List)
          .map((e) => StorageDataPointModel.fromJson(e))
          .toList(),
      currentFreeSpace: (json['currentFreeSpace'] as num).toDouble(),
      totalSpace: (json['totalSpace'] as num).toDouble(),
      period: json['period'],
      categoryBreakdown: [], // Will be populated by repository
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataPoints': dataPoints
          .map(
            (e) => {
              'date': e.date.toIso8601String(),
              'usedSpace': e.usedSpace,
              'freeSpace': e.freeSpace,
            },
          )
          .toList(),
      'currentFreeSpace': currentFreeSpace,
      'totalSpace': totalSpace,
      'period': period,
      'categoryBreakdown': categoryBreakdown
          .map(
            (cat) => {
              'id': cat.id,
              'name': cat.name,
              'sizeInBytes': cat.sizeInBytes,
              'fileCount': cat.fileCount,
            },
          )
          .toList(),
    };
  }
}
