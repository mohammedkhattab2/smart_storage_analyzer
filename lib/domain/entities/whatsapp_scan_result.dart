import 'package:equatable/equatable.dart';
import 'whatsapp_media_item.dart';

/// Summary data for a specific WhatsApp media category
class WhatsAppCategorySummary extends Equatable {
  final WhatsAppMediaType type;
  final String title;
  final int totalBytes;
  final int fileCount;
  final List<WhatsAppMediaItem> items;

  const WhatsAppCategorySummary({
    required this.type,
    required this.title,
    required this.totalBytes,
    required this.fileCount,
    required this.items,
  });

  @override
  List<Object?> get props => [type, title, totalBytes, fileCount, items];
}

/// Aggregated result of a complete WhatsApp media scan
class WhatsAppScanResult extends Equatable {
  final int totalSizeBytes;
  final int cleanableSizeBytes;
  final int totalFilesCount;
  final Map<WhatsAppMediaType, WhatsAppCategorySummary> categories;
  final List<WhatsAppMediaItem> allItems;
  final DateTime scannedAt;

  const WhatsAppScanResult({
    required this.totalSizeBytes,
    required this.cleanableSizeBytes,
    required this.totalFilesCount,
    required this.categories,
    required this.allItems,
    required this.scannedAt,
  });

  /// Factory constructor to aggregate raw media items
  factory WhatsAppScanResult.fromItems(List<WhatsAppMediaItem> items) {
    int totalBytes = 0;
    int cleanableBytes = 0;

    final Map<WhatsAppMediaType, List<WhatsAppMediaItem>> grouped = {
      for (final type in WhatsAppMediaType.values) type: [],
    };

    for (final item in items) {
      totalBytes += item.sizeBytes;
      if (item.isQuickCleanRecommended) {
        cleanableBytes += item.sizeBytes;
      }
      grouped[item.category]?.add(item);
    }

    final Map<WhatsAppMediaType, WhatsAppCategorySummary> categorySummaries = {};

    String getTitle(WhatsAppMediaType type) {
      switch (type) {
        case WhatsAppMediaType.voiceNotes:
          return 'Voice Notes';
        case WhatsAppMediaType.sentMedia:
          return 'Sent Media';
        case WhatsAppMediaType.statuses:
          return 'Statuses';
        case WhatsAppMediaType.images:
          return 'Photos & Images';
        case WhatsAppMediaType.videos:
          return 'Videos';
        case WhatsAppMediaType.audio:
          return 'Audio & Music';
        case WhatsAppMediaType.documents:
          return 'Documents';
        case WhatsAppMediaType.stickers:
          return 'Stickers';
        case WhatsAppMediaType.animatedGifs:
          return 'GIFs';
      }
    }

    for (final entry in grouped.entries) {
      final type = entry.key;
      final categoryItems = entry.value;
      final int size = categoryItems.fold<int>(0, (sum, i) => sum + i.sizeBytes);

      categorySummaries[type] = WhatsAppCategorySummary(
        type: type,
        title: getTitle(type),
        totalBytes: size,
        fileCount: categoryItems.length,
        items: List.unmodifiable(categoryItems),
      );
    }

    return WhatsAppScanResult(
      totalSizeBytes: totalBytes,
      cleanableSizeBytes: cleanableBytes,
      totalFilesCount: items.length,
      categories: categorySummaries,
      allItems: List.unmodifiable(items),
      scannedAt: DateTime.now(),
    );
  }

  /// Empty result state
  factory WhatsAppScanResult.empty() {
    return WhatsAppScanResult(
      totalSizeBytes: 0,
      cleanableSizeBytes: 0,
      totalFilesCount: 0,
      categories: const {},
      allItems: const [],
      scannedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        totalSizeBytes,
        cleanableSizeBytes,
        totalFilesCount,
        categories,
        allItems,
        scannedAt,
      ];
}
