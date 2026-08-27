import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';

class StorageAnalysisResults {
  final int totalFilesScanned;
  final int totalSpaceUsed;
  final int totalSpaceAvailable;

  // Cleanup opportunities
  final List<FileItem> cacheFiles;
  final List<FileItem> temporaryFiles;
  final List<FileItem> largeOldFiles;
  final List<FileItem> duplicateFiles;
  final List<FileItem> thumbnails;

  // Category breakdown after deep scan
  final List<Category> detailedCategories;

  // Total space that can be freed
  final int totalCleanupPotential;

  // Analysis metadata
  final DateTime analysisDate;
  final Duration analysisDuration;

  const StorageAnalysisResults({
    required this.totalFilesScanned,
    required this.totalSpaceUsed,
    required this.totalSpaceAvailable,
    required this.cacheFiles,
    required this.temporaryFiles,
    required this.largeOldFiles,
    required this.duplicateFiles,
    required this.thumbnails,
    required this.detailedCategories,
    required this.totalCleanupPotential,
    required this.analysisDate,
    required this.analysisDuration,
  });

  // Helper getters
  int get totalCacheSize =>
      cacheFiles.fold(0, (sum, file) => sum + file.sizeInBytes);
  int get totalTempSize =>
      temporaryFiles.fold(0, (sum, file) => sum + file.sizeInBytes);
  int get totalDuplicatesSize =>
      duplicateFiles.fold(0, (sum, file) => sum + file.sizeInBytes);
  int get totalLargeOldSize =>
      largeOldFiles.fold(0, (sum, file) => sum + file.sizeInBytes);
  int get totalThumbnailsSize =>
      thumbnails.fold(0, (sum, file) => sum + file.sizeInBytes);

  List<CleanupCategory> get cleanupCategories => [
    if (cacheFiles.isNotEmpty)
      CleanupCategory(
        name: 'Cache Files',
        icon: 'cache',
        files: cacheFiles,
        totalSize: totalCacheSize,
        description: 'Temporary cached data stored by apps',
      ),
    if (temporaryFiles.isNotEmpty)
      CleanupCategory(
        name: 'Temporary & Residual Files',
        icon: 'temp_files',
        files: temporaryFiles,
        totalSize: totalTempSize,
        description: 'System temp, .tmp files & leftover downloads',
      ),
    if (thumbnails.isNotEmpty)
      CleanupCategory(
        name: 'Thumbnails',
        icon: 'thumbnails',
        files: thumbnails,
        totalSize: totalThumbnailsSize,
        description: 'Cached preview images and gallery thumbnails',
      ),
    if (duplicateFiles.isNotEmpty)
      CleanupCategory(
        name: 'Duplicate Files',
        icon: 'duplicates',
        files: duplicateFiles,
        totalSize: totalDuplicatesSize,
        description: 'Exact identical copies of files found in storage',
      ),
    if (largeOldFiles.isNotEmpty)
      CleanupCategory(
        name: 'Large & Old Files',
        icon: 'old_files',
        files: largeOldFiles,
        totalSize: totalLargeOldSize,
        description: 'Files > 30MB or older than 90 days',
      ),
  ];
}

class CleanupCategory {
  final String name;
  final String icon;
  final List<FileItem> files;
  final int totalSize;
  final String description;

  const CleanupCategory({
    required this.name,
    required this.icon,
    required this.files,
    required this.totalSize,
    required this.description,
  });
}
