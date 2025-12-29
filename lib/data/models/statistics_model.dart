import 'package:smart_storage_analyzer/domain/entities/statistics.dart';

class StorageDataPointModel extends StorageDataPoint {
  const StorageDataPointModel({
    required DateTime date,
    required double usedSpace,
    required double freeSpace,
  }) : super(
          date: date,
          usedSpace: usedSpace,
          freeSpace: freeSpace,
        );

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
    required List<StorageDataPoint> dataPoints,
    required double currentFreeSpace,
    required double totalSpace,
    required String period,
  }) : super(
          dataPoint: dataPoints,
          currentFreeSpace: currentFreeSpace,
          totalSpace: totalSpace,
          period: period,
        );

  factory StorageStatisticsModel.fromJson(Map<String, dynamic> json) {
    return StorageStatisticsModel(
      dataPoints: (json['dataPoints'] as List)
          .map((e) => StorageDataPointModel.fromJson(e))
          .toList(),
      currentFreeSpace: (json['currentFreeSpace'] as num).toDouble(),
      totalSpace: (json['totalSpace'] as num).toDouble(),
      period: json['period'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataPoints': dataPoint.map((e) => {
        'date': e.date.toIso8601String(),
        'usedSpace': e.usedSpace,
        'freeSpace': e.freeSpace,
      }).toList(),
      'currentFreeSpace': currentFreeSpace,
      'totalSpace': totalSpace,
      'period': period,
    };
  }
}

