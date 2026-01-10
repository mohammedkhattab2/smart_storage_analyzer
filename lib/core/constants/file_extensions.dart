class FileExtensions {
  FileExtensions._();
  // === Image Extensions ===
  static const List<String> imageExtensions = [
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
    '.heif',
    '.raw',
    '.cr2',
    '.nef',
    '.orf',
    '.sr2',
    '.psd',
    '.ai',
    '.eps',
  ];

  // === Video Extensions (Comprehensive) ===
  static const List<String> videoExtensions = [
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
    '.mpeg',
    '.mpe',
    '.mpv',
    '.m2v',
    '.svi',
    '.3g2',
    '.mxf',
    '.roq',
    '.nsv',
    '.f4v',
    '.f4p',
    '.f4a',
    '.f4b',
    '.mod',
    '.vob',
    '.ogv',
    '.drc',
    '.mng',
    '.qt',
    '.yuv',
    '.rm',
    '.rmvb',
    '.asf',
    '.amv',
    '.m2ts',
    '.mts',
    '.m2t',
    '.ts',
    '.rec',
  ];

  // === Audio Extensions (Comprehensive) ===
  static const List<String> audioExtensions = [
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.wma',
    '.m4a',
    '.opus',
    '.amr',
    '.ape',
    '.au',
    '.aiff',
    '.dss',
    '.dvf',
    '.m4b',
    '.m4p',
    '.mmf',
    '.mpc',
    '.msv',
    '.nmf',
    '.oga',
    '.mogg',
    '.ra',
    '.rf64',
    '.sln',
    '.tta',
    '.voc',
    '.vox',
    '.wv',
    '.8svx',
    '.cda',
  ];

  // === Document Extensions (Comprehensive) ===
  static const List<String> documentExtensions = [
    // Text documents
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.odt',
    '.rtf',
    '.tex',
    '.wpd',
    '.md',
    // Spreadsheets
    '.xls',
    '.xlsx',
    '.ods',
    '.csv',
    '.tsv',
    // Presentations
    '.ppt',
    '.pptx',
    '.odp',
    '.pps',
    '.ppsx',
    // E-books
    '.epub',
    '.mobi',
    '.azw',
    '.azw3',
    '.fb2',
    '.lit',
    // Other documents
    '.xml',
    '.json',
    '.log',
    '.ini',
    '.cfg',
    '.conf',
    '.properties',
    '.html',
    '.htm',
    '.xhtml',
    '.mhtml',
    '.chm',
  ];

  // === App Extensions (Android) ===
  static const List<String> appExtensions = [
    '.apk', 
    '.xapk', 
    '.aab',
    '.apks',
  ];

  // === Archive Extensions (for future use) ===
  static const List<String> archiveExtensions = [
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.bz2',
    '.xz',
    '.iso',
    '.dmg',
    '.cab',
  ];

  static String getFileCategory(String filePath) {
    final extension = filePath.toLowerCase();

    if (imageExtensions.any((ext) => extension.endsWith(ext))) {
      return 'Image';
    } else if (videoExtensions.any((ext) => extension.endsWith(ext))) {
      return 'Video';
    } else if (audioExtensions.any((ext) => extension.endsWith(ext))) {
      return 'Audio';
    } else if (documentExtensions.any((ext) => extension.endsWith(ext))) {
      return 'Document';
    } else if (appExtensions.any((ext) => extension.endsWith(ext))) {
      return 'App';
    } else if (archiveExtensions.any((ext) => extension.endsWith(ext))) {
      return 'Archive';
    } else {
      return 'Others';  // Changed from 'Unknown' to 'Others' to match category name
    }
  }

  // Helper method to check if a file is a media file
  static bool isMediaFile(String filePath) {
    final extension = filePath.toLowerCase();
    return imageExtensions.any((ext) => extension.endsWith(ext)) ||
           videoExtensions.any((ext) => extension.endsWith(ext)) ||
           audioExtensions.any((ext) => extension.endsWith(ext));
  }

  // Get all known extensions for exclusion purposes
  static List<String> getAllKnownExtensions() {
    return [
      ...imageExtensions,
      ...videoExtensions,
      ...audioExtensions,
      ...documentExtensions,
      ...appExtensions,
      ...archiveExtensions,
    ];
  }

  // Get extensions for a specific category
  static List<String> getExtensionsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'images':
      case 'image':
        return imageExtensions;
      case 'videos':
      case 'video':
        return videoExtensions;
      case 'audio':
        return audioExtensions;
      case 'documents':
      case 'document':
        return documentExtensions;
      case 'apps':
      case 'app':
        return appExtensions;
      case 'archives':
      case 'archive':
        return archiveExtensions;
      default:
        return [];
    }
  }
}
