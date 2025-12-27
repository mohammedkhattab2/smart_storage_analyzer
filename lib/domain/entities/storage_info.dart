import 'package:equatable/equatable.dart';

class StorageInfo extends Equatable {
  final double totalSpace;
  final double usedSpace;
  final double freeSpace;
  final DateTime lastUpdated;

  const StorageInfo({
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
    required this.lastUpdated,
  });

  double get usagePercentage => (usedSpace / totalSpace) * 100;

  @override
  List <Object?> get props => [totalSpace, usedSpace, freeSpace, lastUpdated];
}
