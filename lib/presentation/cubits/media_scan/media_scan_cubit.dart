import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/core/services/media_scan_cache_service.dart';
import 'package:smart_storage_analyzer/core/services/saf_media_scanner_service.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

// States
abstract class MediaScanState extends Equatable {
  const MediaScanState();

  @override
  List<Object?> get props => [];
}

class MediaScanInitial extends MediaScanState {
  final MediaType mediaType;
  
  const MediaScanInitial(this.mediaType);
  
  @override
  List<Object?> get props => [mediaType];
}

class MediaScanNoFolder extends MediaScanState {
  final MediaType mediaType;
  
  const MediaScanNoFolder(this.mediaType);
  
  @override
  List<Object?> get props => [mediaType];
}

class MediaScanScanning extends MediaScanState {
  final MediaType mediaType;
  final String? folderName;
  
  const MediaScanScanning(this.mediaType, {this.folderName});
  
  @override
  List<Object?> get props => [mediaType, folderName];
}

class MediaScanLoaded extends MediaScanState {
  final MediaType mediaType;
  final List<ScannedMediaFile> files;
  final int totalSize;
  final int fileCount;
  final String folderName;
  final String folderUri;
  final Set<String> selectedFileIds;
  final bool isSelectionMode;

  const MediaScanLoaded({
    required this.mediaType,
    required this.files,
    required this.totalSize,
    required this.fileCount,
    required this.folderName,
    required this.folderUri,
    this.selectedFileIds = const {},
    this.isSelectionMode = false,
  });

  List<ScannedMediaFile> get largestFiles {
    final sorted = List<ScannedMediaFile>.from(files)
      ..sort((a, b) => b.size.compareTo(a.size));
    return sorted.take(10).toList();
  }

  int get selectedCount => selectedFileIds.length;
  
  int get selectedSize {
    return files
        .where((f) => selectedFileIds.contains(f.id))
        .fold(0, (sum, f) => sum + f.size);
  }

  MediaScanLoaded copyWith({
    MediaType? mediaType,
    List<ScannedMediaFile>? files,
    int? totalSize,
    int? fileCount,
    String? folderName,
    String? folderUri,
    Set<String>? selectedFileIds,
    bool? isSelectionMode,
  }) {
    return MediaScanLoaded(
      mediaType: mediaType ?? this.mediaType,
      files: files ?? this.files,
      totalSize: totalSize ?? this.totalSize,
      fileCount: fileCount ?? this.fileCount,
      folderName: folderName ?? this.folderName,
      folderUri: folderUri ?? this.folderUri,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  @override
  List<Object?> get props => [
        mediaType,
        files,
        totalSize,
        fileCount,
        folderName,
        folderUri,
        selectedFileIds,
        isSelectionMode,
      ];
}

class MediaScanError extends MediaScanState {
  final MediaType mediaType;
  final String message;

  const MediaScanError(this.mediaType, this.message);

  @override
  List<Object?> get props => [mediaType, message];
}

// Cubit
class MediaScanCubit extends Cubit<MediaScanState> {
  final SafMediaScannerService _scannerService;
  final MediaScanCacheService _cacheService;
  final MediaType mediaType;

  MediaScanCubit({
    required this.mediaType,
    SafMediaScannerService? scannerService,
    MediaScanCacheService? cacheService,
  })  : _scannerService = scannerService ?? SafMediaScannerService(),
        _cacheService = cacheService ?? MediaScanCacheService(),
        super(MediaScanInitial(mediaType));

  /// Initialize and check for cached results or persisted folder
  Future<void> initialize() async {
    Logger.info('[MediaScanCubit] Initializing for ${mediaType.value}');
    
    try {
      // First, check if we have a valid cached result
      final cachedResult = _cacheService.getCachedResult(mediaType);
      if (cachedResult != null) {
        Logger.info('[MediaScanCubit] Using cached result for ${mediaType.value}');
        emit(MediaScanLoaded(
          mediaType: mediaType,
          files: cachedResult.result.files,
          totalSize: cachedResult.result.totalSize,
          fileCount: cachedResult.result.fileCount,
          folderName: cachedResult.folderName,
          folderUri: cachedResult.folderUri,
        ));
        return;
      }
      
      // No cache, check for persisted folder
      final persistedUri = await _scannerService.getPersistedMediaUri(mediaType);
      
      if (persistedUri != null && persistedUri.isValid) {
        Logger.info('[MediaScanCubit] Found persisted folder: ${persistedUri.name}');
        // Auto-scan the persisted folder
        await _scanFolder(persistedUri.uri, persistedUri.name);
      } else {
        Logger.info('[MediaScanCubit] No persisted folder, showing selection prompt');
        emit(MediaScanNoFolder(mediaType));
      }
    } catch (e) {
      Logger.error('[MediaScanCubit] Error initializing', e);
      emit(MediaScanNoFolder(mediaType));
    }
  }

  /// Open folder picker and scan
  Future<void> selectAndScanFolder() async {
    Logger.info('[MediaScanCubit] Opening folder picker for ${mediaType.value}');
    
    try {
      emit(MediaScanScanning(mediaType));
      
      final selection = await _scannerService.selectMediaFolder(mediaType);
      
      if (selection == null) {
        Logger.info('[MediaScanCubit] User cancelled folder selection');
        // Check if we have a previous state to return to
        final persistedUri = await _scannerService.getPersistedMediaUri(mediaType);
        if (persistedUri != null && persistedUri.isValid) {
          await _scanFolder(persistedUri.uri, persistedUri.name);
        } else {
          emit(MediaScanNoFolder(mediaType));
        }
        return;
      }
      
      await _scanFolder(selection.uri, selection.name);
    } catch (e) {
      Logger.error('[MediaScanCubit] Error selecting folder', e);
      emit(MediaScanError(mediaType, 'Failed to select folder: ${e.toString()}'));
    }
  }

  /// Scan a specific folder
  Future<void> _scanFolder(String uri, String folderName) async {
    Logger.info('[MediaScanCubit] Scanning folder: $folderName');
    
    emit(MediaScanScanning(mediaType, folderName: folderName));
    
    try {
      final result = await _scannerService.scanMediaFolder(uri, mediaType);
      
      Logger.success(
        '[MediaScanCubit] Scan complete: ${result.fileCount} files, '
        '${_formatBytes(result.totalSize)}',
      );
      
      // Cache the result
      _cacheService.cacheResult(mediaType, result, folderName, uri);
      
      emit(MediaScanLoaded(
        mediaType: mediaType,
        files: result.files,
        totalSize: result.totalSize,
        fileCount: result.fileCount,
        folderName: folderName,
        folderUri: uri,
      ));
    } catch (e) {
      Logger.error('[MediaScanCubit] Error scanning folder', e);
      emit(MediaScanError(mediaType, 'Failed to scan folder: ${e.toString()}'));
    }
  }

  /// Rescan the current folder
  Future<void> rescan() async {
    final currentState = state;
    if (currentState is MediaScanLoaded) {
      await _scanFolder(currentState.folderUri, currentState.folderName);
    } else {
      await initialize();
    }
  }

  /// Change folder (select a different one)
  Future<void> changeFolder() async {
    await selectAndScanFolder();
  }

  /// Clear the persisted folder and reset
  Future<void> clearFolder() async {
    Logger.info('[MediaScanCubit] Clearing persisted folder for ${mediaType.value}');
    
    // Clear both cache and persisted URI
    _cacheService.clearCache(mediaType);
    await _scannerService.clearPersistedMediaUri(mediaType);
    emit(MediaScanNoFolder(mediaType));
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    final currentState = state;
    if (currentState is MediaScanLoaded) {
      emit(currentState.copyWith(
        isSelectionMode: !currentState.isSelectionMode,
        selectedFileIds: currentState.isSelectionMode ? {} : currentState.selectedFileIds,
      ));
    }
  }

  /// Toggle file selection
  void toggleFileSelection(String fileId) {
    final currentState = state;
    if (currentState is MediaScanLoaded) {
      final newSelection = Set<String>.from(currentState.selectedFileIds);
      if (newSelection.contains(fileId)) {
        newSelection.remove(fileId);
      } else {
        newSelection.add(fileId);
      }
      
      emit(currentState.copyWith(
        selectedFileIds: newSelection,
        isSelectionMode: newSelection.isNotEmpty,
      ));
    }
  }

  /// Select all files
  void selectAll() {
    final currentState = state;
    if (currentState is MediaScanLoaded) {
      emit(currentState.copyWith(
        selectedFileIds: currentState.files.map((f) => f.id).toSet(),
        isSelectionMode: true,
      ));
    }
  }

  /// Clear selection
  void clearSelection() {
    final currentState = state;
    if (currentState is MediaScanLoaded) {
      emit(currentState.copyWith(
        selectedFileIds: {},
        isSelectionMode: false,
      ));
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}