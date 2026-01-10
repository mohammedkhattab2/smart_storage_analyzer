import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/services/others_scanner_service.dart';

// States
abstract class OthersScanState {}

class OthersScanInitial extends OthersScanState {}

class OthersScanLoading extends OthersScanState {}

class OthersScanSelecting extends OthersScanState {}

class OthersScanScanning extends OthersScanState {}

class OthersScanNoFolder extends OthersScanState {}

class OthersScanSuccess extends OthersScanState {
  final List<OthersFile> files;
  final String folderName;
  
  OthersScanSuccess({
    required this.files,
    required this.folderName,
  });
}

class OthersScanEmpty extends OthersScanState {
  final String folderName;
  
  OthersScanEmpty({required this.folderName});
}

class OthersScanError extends OthersScanState {
  final String message;
  
  OthersScanError({required this.message});
}

// Cubit
class OthersScanCubit extends Cubit<OthersScanState> {
  final OthersScannerService _scannerService;
  
  OthersScanCubit(this._scannerService) : super(OthersScanInitial());
  
  Future<void> checkSavedFolder() async {
    emit(OthersScanLoading());
    
    try {
      // Check if we have a persisted URI
      if (_scannerService.persistedUri != null) {
        // Check if we have cached files
        if (_scannerService.cachedOthers.isNotEmpty) {
          final folderName = _scannerService.getFolderName() ?? 'Selected Folder';
          emit(OthersScanSuccess(
            files: _scannerService.cachedOthers,
            folderName: folderName,
          ));
        } else {
          // We have a folder selected but no cached files, scan them
          await scanOthers();
        }
      } else {
        // No folder selected yet
        emit(OthersScanNoFolder());
      }
    } catch (e) {
      emit(OthersScanError(message: 'Failed to check saved folder: $e'));
    }
  }
  
  Future<void> selectOthersFolder() async {
    emit(OthersScanSelecting());
    
    try {
      final uri = await _scannerService.selectOthersFolder();
      
      if (uri != null) {
        // Folder selected, now scan it
        await scanOthers();
      } else {
        // User cancelled folder selection
        // Check if we had a previous folder
        if (_scannerService.persistedUri != null) {
          await checkSavedFolder();
        } else {
          emit(OthersScanNoFolder());
        }
      }
    } catch (e) {
      emit(OthersScanError(message: 'Failed to select folder: $e'));
    }
  }
  
  Future<void> scanOthers({bool forceRefresh = false}) async {
    emit(OthersScanScanning());
    
    try {
      final files = await _scannerService.scanOthers(forceRefresh: forceRefresh);
      final folderName = _scannerService.getFolderName() ?? 'Selected Folder';
      
      if (files.isNotEmpty) {
        emit(OthersScanSuccess(
          files: files,
          folderName: folderName,
        ));
      } else {
        emit(OthersScanEmpty(folderName: folderName));
      }
    } catch (e) {
      emit(OthersScanError(message: 'Failed to scan files: $e'));
    }
  }
  
  Future<void> clearSelection() async {
    await _scannerService.clearPersistedUri();
    emit(OthersScanNoFolder());
  }
  
  int getCachedCount() => _scannerService.getCachedOthersCount();
  int getCachedSize() => _scannerService.getCachedOthersSize();
  bool hasPersistedUri() => _scannerService.persistedUri != null;
}