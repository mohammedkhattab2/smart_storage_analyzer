/// File category enumeration for categorizing files based on their type
enum FileCategory {
  all,
  large,
  duplicates,
  old,
  images,
  videos,
  audio,
  documents,
  apps,
  others,
}

/// Extension methods for FileCategory
extension FileCategoryExtension on FileCategory {
  /// Get the string representation of the category
  String get name {
    switch (this) {
      case FileCategory.all:
        return 'All';
      case FileCategory.large:
        return 'Large';
      case FileCategory.duplicates:
        return 'Duplicates';
      case FileCategory.old:
        return 'Old';
      case FileCategory.images:
        return 'Images';
      case FileCategory.videos:
        return 'Videos';
      case FileCategory.audio:
        return 'Audio';
      case FileCategory.documents:
        return 'Documents';
      case FileCategory.apps:
        return 'Apps';
      case FileCategory.others:
        return 'Others';
    }
  }

  /// Get the category ID used for mapping to Category entity
  String get id {
    switch (this) {
      case FileCategory.all:
        return 'all';
      case FileCategory.large:
        return 'large';
      case FileCategory.duplicates:
        return 'duplicates';
      case FileCategory.old:
        return 'old';
      case FileCategory.images:
        return 'images';
      case FileCategory.videos:
        return 'videos';
      case FileCategory.audio:
        return 'audio';
      case FileCategory.documents:
        return 'documents';
      case FileCategory.apps:
        return 'apps';
      case FileCategory.others:
        return 'others';
    }
  }

  /// Create FileCategory from string
  static FileCategory fromString(String value) {
    return FileCategory.values.firstWhere(
      (category) => category.id == value.toLowerCase(),
      orElse: () => FileCategory.others,
    );
  }

  /// Determine file category based on file extension
  static FileCategory fromExtension(String extension) {
    final ext = extension.toLowerCase();

    // Image extensions
    const imageExts = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.svg',
      '.ico',
      '.tiff',
      '.heic',
    ];

    // Video extensions
    const videoExts = [
      '.mp4',
      '.avi',
      '.mkv',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
      '.m4v',
      '.mpg',
      '.3gp',
    ];

    // Audio extensions
    const audioExts = [
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.ogg',
      '.wma',
      '.m4a',
      '.opus',
      '.amr',
    ];

    // Document extensions
    const documentExts = [
      '.pdf',
      '.doc',
      '.docx',
      '.txt',
      '.odt',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.csv',
    ];

    // App extensions
    const appExts = ['.apk', '.xapk', '.aab'];

    if (imageExts.contains(ext)) {
      return FileCategory.images;
    } else if (videoExts.contains(ext)) {
      return FileCategory.videos;
    } else if (audioExts.contains(ext)) {
      return FileCategory.audio;
    } else if (documentExts.contains(ext)) {
      return FileCategory.documents;
    } else if (appExts.contains(ext)) {
      return FileCategory.apps;
    } else {
      return FileCategory.others;
    }
  }

  /// Convert to JSON-compatible string
  String toJson() => id;
}
