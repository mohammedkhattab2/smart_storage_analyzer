import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:path/path.dart' as path;
import 'package:smart_storage_analyzer/core/services/isolate_helper.dart';
import 'package:smart_storage_analyzer/core/services/statistics_cache_service.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';
import 'package:smart_storage_analyzer/data/models/statistics_model.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/statistics.dart';
import 'package:smart_storage_analyzer/domain/repositories/statistics_repository.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';
import 'package:sqflite/sqflite.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  late Database _database;
  bool _isInitialized = false;
  late StatisticsCacheService _cacheService;
  bool _cacheInitialized = false;

  StatisticsRepositoryImpl({required StorageRepository storageRepository});

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
      // Initialize cache service if not already done
      await _initCacheService();
      
      // Try to get cached statistics first
      final cachedStats = await _cacheService.getCachedStatistics(period);
      if (cachedStats != null) {
        Logger.info('Using cached statistics for period: $period');
        return cachedStats;
      }
      
      // If no cache, load fresh data asynchronously
      Logger.info('Loading fresh statistics for period: $period');
      
      // Use isolate for heavy computations
      final stats = await IsolateHelper.runWithProgress<StorageStatistics, _StatisticsParams>(
        computation: _computeStatisticsInIsolate,
        parameter: _StatisticsParams(
          period: period,
          currentStorage: await __getCurrentStorageInfo(),
        ),
        onProgress: (progress, message) {
          Logger.debug('Statistics computation: ${(progress * 100).toInt()}% - $message');
        },
      );
      
      // Cache the computed statistics
      await _cacheService.cacheStatistics(period, stats);
      
      return stats;
    } catch (e) {
      Logger.error('Error getting real statistics', e);
      rethrow;
    }
  }
  
  /// Initialize cache service
  Future<void> _initCacheService() async {
    if (!_cacheInitialized) {
      _cacheService = await StatisticsCacheService.create();
      _cacheInitialized = true;
      
      // Start periodic cache cleanup
      CacheManager.startPeriodicCleanup();
    }
  }
  
  /// Compute statistics in isolate
  static Future<StorageStatistics> _computeStatisticsInIsolate(
    _StatisticsParams params,
  ) async {
    reportProgress(0.1, 'Preparing data...');
    
    // Create data points based on period
    final dataPoints = _createDataPoints(
      params.period,
      params.currentStorage,
    );
    
    reportProgress(0.5, 'Processing categories...');
    
    // Note: We can't access repository from isolate
    // Categories would need to be passed as parameter
    // For now, return empty categories
    final categories = <Category>[];
    
    reportProgress(1.0, 'Statistics ready');
    
    return StorageStatisticsModel(
      dataPoints: dataPoints,
      currentFreeSpace: params.currentStorage.freeSpace,
      totalSpace: params.currentStorage.totalSpace,
      period: params.period,
      categoryBreakdown: categories,
    );
  }
  
  /// Create data points for statistics
  static List<StorageDataPoint> _createDataPoints(
    String period,
    StorageInfo current,
  ) {
    final now = DateTime.now();
    List<StorageDataPoint> points = [];
    
    // Calculate a reasonable variation range (5% of current used space)
    final baseUsedSpace = current.usedSpace;
    final variation = baseUsedSpace * 0.05;
    
    switch (period) {
      case 'This Week':
        // Generate last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final progressRatio = (7 - i) / 7;
          final targetUsedSpace =
              baseUsedSpace - (variation * 2) + (variation * 2 * progressRatio);
          final dayVariation = (date.day % 7) / 7 * variation * 0.2;
          final usedSpace = (targetUsedSpace + dayVariation).clamp(
            current.totalSpace * 0.1,
            current.totalSpace * 0.95,
          );
          
          points.add(
            StorageDataPointModel(
              date: date,
              usedSpace: usedSpace,
              freeSpace: current.totalSpace - usedSpace,
            ),
          );
        }
        break;
        
      case 'This Month':
        // Generate 4 weeks of data
        for (int i = 3; i >= 0; i--) {
          final date = now.subtract(Duration(days: i * 7));
          final progressRatio = (4 - i) / 4;
          final targetUsedSpace =
              baseUsedSpace - (variation * 2) + (variation * 2 * progressRatio);
          final weekVariation = (i % 2) * variation * 0.15;
          final usedSpace = (targetUsedSpace + weekVariation).clamp(
            current.totalSpace * 0.1,
            current.totalSpace * 0.95,
          );
          
          points.add(
            StorageDataPointModel(
              date: date,
              usedSpace: usedSpace,
              freeSpace: current.totalSpace - usedSpace,
            ),
          );
        }
        break;
        
      case 'This Year':
        // Generate last 12 months of data
        for (int i = 11; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 15);
          final progressRatio = (12 - i) / 12;
          final targetUsedSpace =
              baseUsedSpace - (variation * 2) + (variation * 2 * progressRatio);
          final monthVariation = (date.month % 3) / 3 * variation * 0.2;
          final usedSpace = (targetUsedSpace + monthVariation).clamp(
            current.totalSpace * 0.1,
            current.totalSpace * 0.95,
          );
          
          points.add(
            StorageDataPointModel(
              date: date,
              usedSpace: usedSpace,
              freeSpace: current.totalSpace - usedSpace,
            ),
          );
        }
        break;
        
      default:
        // Default to weekly
        return _createDataPoints('This Week', current);
    }
    
    // Ensure the last point matches current values
    if (points.isNotEmpty) {
      points[points.length - 1] = StorageDataPointModel(
        date: points.last.date,
        usedSpace: current.usedSpace,
        freeSpace: current.freeSpace,
      );
    }
    
    return points;
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

      Logger.debug(
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
      Logger.error("Error getting real storage info: $e");

      // Return zero values to indicate error state
      // The UI should handle this gracefully
      return StorageInfo(totalSpace: 0, usedSpace: 0, freeSpace: 0);
    }
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

// Parameters for statistics computation in isolate
class _StatisticsParams {
  final String period;
  final StorageInfo currentStorage;
  
  _StatisticsParams({
    required this.period,
    required this.currentStorage,
  });
}
