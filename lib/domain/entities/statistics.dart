import 'package:equatable/equatable.dart';

abstract class StorageDataPoint extends Equatable {
  final DateTime date;
  final double usedSpace;
  final double freeSpace;
  const StorageDataPoint({
    required this.date,
    required this.usedSpace,
    required this.freeSpace,
  });

  @override
  List<Object?> get props => [date, usedSpace, freeSpace];
}

abstract class StorageStatistics extends Equatable {
  final List<StorageDataPoint> dataPoints;
  final double currentFreeSpace;
  final double totalSpace;
  final String period; // "This Week", "This Month", "This Year"

  const StorageStatistics({
    required this.dataPoints,
    required this.currentFreeSpace,
    required this.totalSpace,
    required this.period,
  });
  @override
  List<Object> get props => [dataPoints, currentFreeSpace, totalSpace, period];
}
