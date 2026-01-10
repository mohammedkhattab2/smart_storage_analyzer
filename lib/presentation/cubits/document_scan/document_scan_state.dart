part of 'document_scan_cubit.dart';

/// Base class for document scan states
abstract class DocumentScanState extends Equatable {
  const DocumentScanState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state
class DocumentScanInitial extends DocumentScanState {
  const DocumentScanInitial();
}

/// Loading state
class DocumentScanLoading extends DocumentScanState {
  const DocumentScanLoading();
}

/// State when no folder is selected (user needs to select)
class DocumentScanNoFolder extends DocumentScanState {
  const DocumentScanNoFolder();
}

/// State when selecting a folder
class DocumentScanSelecting extends DocumentScanState {
  const DocumentScanSelecting();
}

/// State when scanning documents
class DocumentScanScanning extends DocumentScanState {
  const DocumentScanScanning();
}

/// State when no folder access is granted
class DocumentScanNoAccess extends DocumentScanState {
  final String message;
  
  const DocumentScanNoAccess({
    required this.message,
  });
  
  @override
  List<Object?> get props => [message];
}

/// State when documents are loaded successfully
class DocumentScanSuccess extends DocumentScanState {
  final List<DocumentFile> documents;
  final String folderName;
  final int totalSize;
  final Map<String, List<DocumentFile>> categories;
  
  const DocumentScanSuccess({
    required this.documents,
    required this.folderName,
    required this.totalSize,
    required this.categories,
  });
  
  @override
  List<Object?> get props => [documents, folderName, totalSize, categories];
  
  /// Get document count
  int get documentCount => documents.length;
  
  /// Get total size in MB
  double get totalSizeInMB => totalSize / (1024 * 1024);
  
  /// Check if there are any documents
  bool get hasDocuments => documents.isNotEmpty;
}

/// State when the selected folder is empty
class DocumentScanEmpty extends DocumentScanState {
  final String folderName;
  
  const DocumentScanEmpty({
    required this.folderName,
  });
  
  @override
  List<Object?> get props => [folderName];
}

/// Error state
class DocumentScanError extends DocumentScanState {
  final String message;
  
  const DocumentScanError({
    required this.message,
  });
  
  @override
  List<Object?> get props => [message];
}