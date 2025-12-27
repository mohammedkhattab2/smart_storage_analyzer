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
  ];

  // === Video Extensions ===
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
  ];

  // === Audio Extensions ===
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
  ];

  // === Document Extensions ===
  static const List<String> documentExtensions = [
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

  // === App Extensions (Android) ===
  static const List<String> appExtensions = ['.apk', '.xapk', '.aab'];

  static String getFileCategory(String filePath) {
    final extension = filePath.toLowerCase();

    if (imageExtensions.any((ext)=> extension.endsWith(ext))){
      return 'Image';
    } else if (videoExtensions.any((ext)=> extension.endsWith(ext))){
      return 'Video';
    } else if (audioExtensions.any((ext)=> extension.endsWith(ext))){
      return 'Audio';
    } else if (documentExtensions.any((ext)=> extension.endsWith(ext))){
      return 'Document';
    } else if (appExtensions.any((ext)=> extension.endsWith(ext))){
      return 'App';
    } else {
      return 'Unknown';
    }
  }
}
