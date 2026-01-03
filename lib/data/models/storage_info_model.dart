import 'package:smart_storage_analyzer/domain/entities/storage_info.dart';

class StorageInfoModel extends StorageInfo {
  const StorageInfoModel({
    required double totalSpace,
    required double usedSpace,
    required double freeSpace,
    required DateTime lastUpdated,
  }) : super(
         totalSpace: totalSpace,
         usedSpace: usedSpace,
         freeSpace: freeSpace,
         lastUpdated: lastUpdated,
       );
  factory StorageInfoModel.fromJson(Map<String, dynamic> json) {
    return StorageInfoModel(
      totalSpace: (json['totalSpace'] as num).toDouble(),
      usedSpace: (json['usedSpace'] as num).toDouble(),
      freeSpace: (json['freeSpace'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'totalSpace': totalSpace,
      'usedSpace': usedSpace,
      'freeSpace': freeSpace,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
