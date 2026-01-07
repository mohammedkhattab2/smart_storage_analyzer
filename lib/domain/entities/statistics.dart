import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';

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
  final List<Category> categoryBreakdown; // Added for category usage

  const StorageStatistics({
    required this.dataPoints,
    required this.currentFreeSpace,
    required this.totalSpace,
    required this.period,
    required this.categoryBreakdown,
  });

  @override
  List<Object> get props => [
    dataPoints,
    currentFreeSpace,
    totalSpace,
    period,
    categoryBreakdown,
  ];
}
