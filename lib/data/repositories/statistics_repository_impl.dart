import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:path/path.dart' as path;
import 'package:smart_storage_analyzer/data/models/statistics_model.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';
import 'package:smart_storage_analyzer/domain/repositories/statistics_repository.dart';
import 'package:sqflite/sqflite.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  late Database _database;
  bool _isInitialized = false;

  Future<Database> get database async {
    if (_isInitialized) return _database;
    _database = await _initDatabase();
    _isInitialized = true;
    return _database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathDB = path.join(dbPath, 'storage_statistics.db');
    return await openDatabase(
      pathDB,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE IF NOT EXISTS statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        used_space REAL NOT NULL,
        free_space REAL NOT NULL,
        total_space REAL NOT NULL
      )
    ''');
      },
    );
  }

  @override
  List<String> getAvailablePeriods() {
    return ['This Week', 'This Month', 'This Year'];
  }

  @override
  Future<StorageStatistics> getStatistics(String period) async {
    try {
      final currentStorage = await __getCurrentStorageInfo();
      await _saveDataPoint(currentStorage);
      final dataPoints = await _getHistoricalData(period);
      return StorageStatisticsModel(
        dataPoints: dataPoints,
        currentFreeSpace: currentStorage.freeSpace,
        totalSpace: currentStorage.totalSpace,
        period: period,
      );
    } catch (e) {
      print('Error getting real statistics: $e');
      rethrow;
    }
  }

  Future<StorageInfo> __getCurrentStorageInfo() async {
    try {
      // Get real disk space information
      final diskSpace = DiskSpacePlus();
      final freeSpace = await diskSpace.getFreeDiskSpace ?? 0.0;
      final totalSpace = await diskSpace.getTotalDiskSpace ?? 0.0;

      // Convert from MB to bytes
      final freeSpaceBytes = freeSpace * 1024 * 1024;
      final totalSpaceBytes = totalSpace * 1024 * 1024;
      final usedSpaceBytes = totalSpaceBytes - freeSpaceBytes;

      print(
        'Real Storage Info - Total: ${totalSpaceBytes / (1024 * 1024 * 1024)} GB, '
        'Used: ${usedSpaceBytes / (1024 * 1024 * 1024)} GB, '
        'Free: ${freeSpaceBytes / (1024 * 1024 * 1024)} GB',
      );

      return StorageInfo(
        totalSpace: totalSpaceBytes,
        usedSpace: usedSpaceBytes,
        freeSpace: freeSpaceBytes,
      );
    } catch (e) {
      print("Error getting real storage info: $e");
      // Throw the error to handle it properly in the UI
      throw Exception('Failed to get storage information: $e');
    }
  }

  Future<void> _saveDataPoint(StorageInfo info) async {
    final db = await database;

    await db.insert("statistics", {
      'date': DateTime.now().toIso8601String(),
      'used_space': info.usedSpace,
      'free_space': info.freeSpace,
      'total_space': info.totalSpace,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    final cutoffDate = DateTime.now().subtract(Duration(days: 365));
    await db.delete(
      "statistics",
      where: "date<?",
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  Future<List<StorageDataPoint>> _getHistoricalData(String period) async {
    final db = await database;
    final now = DateTime.now();
    DateTime startDate;
    switch (period) {
      case 'This Week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'This Month':
        startDate = now.subtract(Duration(days: 30));
        break;
      case 'This Year':
        startDate = now.subtract(Duration(days: 365));
        break;
      default:
        startDate = now.subtract(Duration(days: 7));
    }
    final List<Map<String, dynamic>> maps = await db.query(
      "statistics",
      where: "date >= ?",
      whereArgs: [startDate.toIso8601String()],
      orderBy: "date ASC",
    );
    if (maps.isEmpty) {
      final current = await __getCurrentStorageInfo();
      return _createSamplePoints(period, current);
    }
    return maps.map((map) {
      return StorageDataPointModel(
        date: DateTime.parse(map["date"]),
        usedSpace: map["used_space"],
        freeSpace: map["free_space"],
      );
    }).toList();
  }

  List<StorageDataPoint> _createSamplePoints(
    String period,
    StorageInfo current,
  ) {
    final now = DateTime.now();
    List<StorageDataPoint> points = [];
    int numberOfPoints;
    Duration interval;
    switch (period) {
      case 'This Week':
        numberOfPoints = 7;
        interval = Duration(days: 1);
        break;
      case 'This Month':
        numberOfPoints = 30;
        interval = Duration(days: 1);
        break;
      case 'This Year':
        numberOfPoints = 12;
        interval = Duration(days: 30);
        break;
      default:
        numberOfPoints = 7;
        interval = Duration(days: 1);
    }

    // When no historical data exists, create points with current values
    // This represents a new installation or first time usage
    for (int i = numberOfPoints - 1; i >= 0; i--) {
      final date = now.subtract(interval * i);

      points.add(
        StorageDataPointModel(
          date: date,
          usedSpace: current.usedSpace,
          freeSpace: current.freeSpace,
        ),
      );
    }

    return points;
  }
}

// helper class
class StorageInfo {
  final double totalSpace;
  final double freeSpace;
  final double usedSpace;

  StorageInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
  });
}
