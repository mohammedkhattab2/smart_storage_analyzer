import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/presentation/cubits/document_scan/document_scan_cubit.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  @override
  void initState() {
    super.initState();
    // Check for saved folder will be called when cubit is created
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Documents'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          BlocBuilder<DocumentScanCubit, DocumentScanState>(
            builder: (context, state) {
              if (state is DocumentScanSuccess) {
                return Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<DocumentScanCubit>().selectDocumentFolder();
                      },
                      icon: Icon(
                        Icons.folder_open,
                        color: colorScheme.primary,
                      ),
                      tooltip: 'Change Folder',
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<DocumentScanCubit>().scanDocuments(forceRefresh: true);
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: colorScheme.primary,
                      ),
                      tooltip: 'Refresh',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha: 0.02),
              colorScheme.secondary.withValues(alpha: 0.03),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: BlocBuilder<DocumentScanCubit, DocumentScanState>(
          builder: (context, state) {
            if (state is DocumentScanNoFolder) {
              return _buildNoFolderState(context);
            } else if (state is DocumentScanLoading || 
                       state is DocumentScanSelecting || 
                       state is DocumentScanScanning) {
              return _buildLoadingState(context, state);
            } else if (state is DocumentScanSuccess) {
              return _buildSuccessState(context, state);
            } else if (state is DocumentScanEmpty) {
              return _buildEmptyState(context, state);
            } else if (state is DocumentScanError) {
              return _buildErrorState(context, state);
            } else {
              // Default/Initial state
              return _buildLoadingState(context, state);
            }
          },
        ),
      ),
    );
  }

  Widget _buildNoFolderState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Magical icon container with gradient
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                    colorScheme.primaryContainer.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.folder_off_outlined,
                size: 80,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            
            // Title with gradient effect
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Text(
                'No Documents Folder Selected',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            
            // Description card
            Container(
              padding: const EdgeInsets.all(AppSize.paddingLarge),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Due to Android privacy rules, document access requires manual folder selection.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge * 1.5),
            
            // Select folder button with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.read<DocumentScanCubit>().selectDocumentFolder();
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingXLarge,
                      vertical: AppSize.paddingMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open, color: colorScheme.onPrimary),
                        const SizedBox(width: AppSize.paddingSmall),
                        Text(
                          'Select Documents Folder',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSize.paddingLarge),
            
            // Info pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.paddingLarge,
                vertical: AppSize.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSize.paddingSmall),
                  Flexible(
                    child: Text(
                      'Choose Downloads or Documents folder',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, [DocumentScanState? state]) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    String message = 'Loading...';
    if (state is DocumentScanSelecting) {
      message = 'Opening folder picker...';
    } else if (state is DocumentScanScanning) {
      message = 'Scanning documents...';
    } else if (state is DocumentScanLoading) {
      message = 'Loading documents...';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          Text(
            message,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state is DocumentScanScanning) ...[
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              'This may take a few moments',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, DocumentScanSuccess state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (state.documents.isEmpty) {
      return _buildEmptyState(context, DocumentScanEmpty(folderName: state.folderName));
    }
    
    return Column(
      children: [
        // Header with document count
        Container(
          margin: const EdgeInsets.all(AppSize.paddingMedium),
          padding: const EdgeInsets.all(AppSize.paddingLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.3),
                colorScheme.secondaryContainer.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.2),
                      colorScheme.primary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_special,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSize.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.documents.length} documents',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      state.folderName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Document list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingMedium),
            itemCount: state.documents.length,
            itemBuilder: (context, index) {
              final doc = state.documents[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSize.paddingSmall),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surfaceContainer.withValues(alpha: .98),
                      colorScheme.surfaceContainerHighest.withValues(alpha: .95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: .08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: .04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showDocumentOpenDialog(context, doc);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSize.paddingMedium),
                      child: Row(
                        children: [
                          // Document icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getColorForMimeType(doc.mimeType, colorScheme)
                                      .withValues(alpha: 0.2),
                                  _getColorForMimeType(doc.mimeType, colorScheme)
                                      .withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconForMimeType(doc.mimeType),
                              color: _getColorForMimeType(doc.mimeType, colorScheme),
                            ),
                          ),
                          const SizedBox(width: AppSize.paddingMedium),
                          
                          // Document info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  SizeFormatter.formatBytes(doc.size),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // File extension badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getColorForMimeType(doc.mimeType, colorScheme)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getFileExtension(doc.name),
                              style: textTheme.labelSmall?.copyWith(
                                color: _getColorForMimeType(doc.mimeType, colorScheme),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, DocumentScanEmpty state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.folder_open,
                size: 60,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            Text(
              'No Documents Found',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              'No documents found in "${state.folderName}"',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.folder,
                  label: 'Change Folder',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.read<DocumentScanCubit>().selectDocumentFolder();
                  },
                ),
                const SizedBox(width: AppSize.paddingMedium),
                _buildActionButton(
                  context,
                  icon: Icons.refresh,
                  label: 'Refresh',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.read<DocumentScanCubit>().scanDocuments(forceRefresh: true);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, DocumentScanError state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            Text(
              'Error',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              state.message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            _buildActionButton(
              context,
              icon: Icons.refresh,
              label: 'Try Again',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<DocumentScanCubit>().checkSavedFolder();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSize.paddingLarge,
          vertical: AppSize.paddingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  IconData _getIconForMimeType(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Icons.slideshow;
    }
    if (mimeType.contains('text')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  Color _getColorForMimeType(String mimeType, ColorScheme colorScheme) {
    if (mimeType.contains('pdf')) return colorScheme.error;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return colorScheme.primary;
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return colorScheme.tertiary;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return colorScheme.secondary;
    }
    if (mimeType.contains('text')) return colorScheme.onSurfaceVariant;
    return colorScheme.primary;
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return '.${parts.last.toUpperCase()}';
    }
    return '';
  }
  
  void _showDocumentOpenDialog(BuildContext context, dynamic doc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    developer.log('[DOC SCANNER] Opening dialog for: ${doc.name}', name: 'DocumentScanner');
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Document icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _getColorForMimeType(doc.mimeType, colorScheme).withValues(alpha: 0.2),
                      _getColorForMimeType(doc.mimeType, colorScheme).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _getColorForMimeType(doc.mimeType, colorScheme).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getIconForMimeType(doc.mimeType),
                  size: 40,
                  color: _getColorForMimeType(doc.mimeType, colorScheme),
                ),
              ),
              const SizedBox(height: 20),
              
              // File name
              Text(
                doc.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // File info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${SizeFormatter.formatBytes(doc.size)} • ${_getFileExtension(doc.name)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons - wrap in Flexible to prevent overflow
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  
                  // Open button
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      
                      // Show loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text('Opening ${doc.name}...'),
                            ],
                          ),
                          backgroundColor: colorScheme.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      
                      // Open the document using method channel
                      try {
                        developer.log('[DOC SCANNER] Attempting to open document: ${doc.uri}', name: 'DocumentScanner');
                        
                        // Use the method channel to open the SAF document
                        const platform = MethodChannel('com.smarttools.storageanalyzer/native');
                        final result = await platform.invokeMethod('openDocument', {
                          'uri': doc.uri,
                          'mimeType': doc.mimeType,
                        });
                        
                        developer.log('[DOC SCANNER] Open result: $result', name: 'DocumentScanner');
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          if (result != true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not open document'),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        developer.log('[DOC SCANNER] Error opening document: $e', name: 'DocumentScanner');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error opening document: ${e.toString()}'),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: const Text('Open in Phone App'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}