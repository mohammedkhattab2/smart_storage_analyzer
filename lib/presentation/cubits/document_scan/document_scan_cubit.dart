import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/document_scanner_service.dart';
import '../../../core/utils/logger.dart';

part 'document_scan_state.dart';

/// Cubit for managing document scanning state and operations
class DocumentScanCubit extends Cubit<DocumentScanState> {
  final DocumentScannerService _documentScannerService;
  
  DocumentScanCubit({
    required DocumentScannerService documentScannerService,
  })  : _documentScannerService = documentScannerService,
        super(const DocumentScanInitial());
  
  /// Check if we have saved folder and validate it
  Future<void> checkSavedFolder() async {
    try {
      emit(const DocumentScanLoading());
      
      // Check if we have existing folder access
      if (_documentScannerService.hasFolderAccess) {
        Logger.info('[DocumentScanCubit] Existing folder access found');
        
        // Validate the persisted URI
        final isValid = await _documentScannerService.validatePersistedUri();
        
        if (isValid) {
          // Check for cached documents
          final cachedDocs = _documentScannerService.cachedDocuments;
          
          if (cachedDocs != null && cachedDocs.isNotEmpty) {
            // We have cached documents, show them immediately
            emit(DocumentScanSuccess(
              documents: cachedDocs,
              folderName: _documentScannerService.selectedFolderName ?? 'Documents',
              totalSize: _documentScannerService.getTotalDocumentSize(),
              categories: _documentScannerService.getCategorizedDocuments(),
            ));
            
            // Refresh in background
            _refreshDocumentsInBackground();
          } else {
            // No cached documents, scan now
            Logger.info('[DocumentScanCubit] No cached documents, scanning...');
            await scanDocuments();
          }
        } else {
          // URI is invalid, need to select folder again
          emit(const DocumentScanNoFolder());
        }
      } else {
        // No folder selected yet
        emit(const DocumentScanNoFolder());
      }
    } catch (e) {
      Logger.error('[DocumentScanCubit] Error checking saved folder: $e');
      emit(DocumentScanError(message: 'Failed to check saved folder: ${e.toString()}'));
    }
  }
  
  /// Initialize the cubit and check for existing folder access
  /// @deprecated Use checkSavedFolder() instead
  Future<void> initialize() async {
    await checkSavedFolder();
  }
  
  /// Select document folder using SAF
  Future<void> selectDocumentFolder() async {
    await selectFolder();
  }
  
  /// Open folder picker for document access
  Future<void> selectFolder() async {
    try {
      emit(const DocumentScanSelecting());
      
      final selected = await _documentScannerService.selectDocumentFolder();
      
      if (selected) {
        // Folder selected, now scan for documents
        await scanDocuments();
      } else {
        // User cancelled selection
        if (_documentScannerService.hasFolderAccess) {
          // Restore previous state if we had folder access
          final documents = _documentScannerService.cachedDocuments ?? [];
          emit(DocumentScanSuccess(
            documents: documents,
            folderName: _documentScannerService.selectedFolderName ?? 'Documents',
            totalSize: _documentScannerService.getTotalDocumentSize(),
            categories: _documentScannerService.getCategorizedDocuments(),
          ));
        } else {
          // No folder selected
          emit(const DocumentScanNoFolder());
        }
      }
    } catch (e) {
      Logger.error('[DocumentScanCubit] Error selecting folder: $e');
      emit(DocumentScanError(message: 'Failed to select folder: ${e.toString()}'));
    }
  }
  
  /// Scan documents in the selected folder
  Future<void> scanDocuments({bool forceRefresh = false}) async {
    try {
      // Don't emit loading state if we're refreshing in background
      if (forceRefresh || state is! DocumentScanSuccess) {
        emit(const DocumentScanScanning());
      }
      
      final documents = await _documentScannerService.scanDocuments(
        useCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      
      if (documents.isEmpty) {
        emit(DocumentScanEmpty(
          folderName: _documentScannerService.selectedFolderName ?? 'Selected Folder',
        ));
      } else {
        emit(DocumentScanSuccess(
          documents: documents,
          folderName: _documentScannerService.selectedFolderName ?? 'Documents',
          totalSize: _documentScannerService.getTotalDocumentSize(),
          categories: _documentScannerService.getCategorizedDocuments(),
        ));
      }
    } catch (e) {
      Logger.error('[DocumentScanCubit] Error scanning documents: $e');
      emit(DocumentScanError(message: 'Failed to scan documents: ${e.toString()}'));
    }
  }
  
  /// Refresh documents in background without changing UI state
  Future<void> _refreshDocumentsInBackground() async {
    try {
      Logger.info('[DocumentScanCubit] Refreshing documents in background...');
      
      final documents = await _documentScannerService.scanDocuments(
        forceRefresh: true,
      );
      
      // Only update if still in loaded state
      if (state is DocumentScanSuccess) {
        emit(DocumentScanSuccess(
          documents: documents,
          folderName: _documentScannerService.selectedFolderName ?? 'Documents',
          totalSize: _documentScannerService.getTotalDocumentSize(),
          categories: _documentScannerService.getCategorizedDocuments(),
        ));
      }
    } catch (e) {
      Logger.error('[DocumentScanCubit] Error refreshing in background: $e');
    }
  }
  
  /// Clear folder access and reset to initial state
  Future<void> clearFolderAccess() async {
    try {
      emit(const DocumentScanLoading());
      
      await _documentScannerService.clearFolderAccess();
      
      emit(const DocumentScanNoFolder());
    } catch (e) {
      Logger.error('[DocumentScanCubit] Error clearing folder access: $e');
      emit(DocumentScanError(message: 'Failed to clear folder access: ${e.toString()}'));
    }
  }
  
  /// Get document count by category
  Map<String, int> getDocumentCountByCategory() {
    if (state is DocumentScanSuccess) {
      final categories = (state as DocumentScanSuccess).categories;
      return categories.map((key, value) => MapEntry(key, value.length));
    }
    return {};
  }
  
  /// Get total document size in MB
  double getTotalDocumentSizeInMB() {
    if (state is DocumentScanSuccess) {
      return (state as DocumentScanSuccess).totalSize / (1024 * 1024);
    }
    return 0.0;
  }
  
  /// Filter documents by search query
  List<DocumentFile> searchDocuments(String query) {
    if (state is! DocumentScanSuccess) return [];
    
    final documents = (state as DocumentScanSuccess).documents;
    final lowerQuery = query.toLowerCase();
    
    return documents.where((doc) {
      return doc.name.toLowerCase().contains(lowerQuery) ||
          doc.extension.toLowerCase().contains(lowerQuery) ||
          doc.mimeType.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}