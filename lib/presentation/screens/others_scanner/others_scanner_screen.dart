import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/presentation/cubits/others_scan/others_scan_cubit.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';

class OthersScannerScreen extends StatefulWidget {
  const OthersScannerScreen({super.key});

  @override
  State<OthersScannerScreen> createState() => _OthersScannerScreenState();
}

class _OthersScannerScreenState extends State<OthersScannerScreen> {
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
        title: const Text('Others'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          BlocBuilder<OthersScanCubit, OthersScanState>(
            builder: (context, state) {
              if (state is OthersScanSuccess) {
                return Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<OthersScanCubit>().selectOthersFolder();
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
                        context.read<OthersScanCubit>().scanOthers(forceRefresh: true);
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
              colorScheme.tertiary.withValues(alpha: 0.02),
              colorScheme.secondary.withValues(alpha: 0.03),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: BlocBuilder<OthersScanCubit, OthersScanState>(
          builder: (context, state) {
            if (state is OthersScanNoFolder) {
              return _buildNoFolderState(context);
            } else if (state is OthersScanLoading || 
                       state is OthersScanSelecting || 
                       state is OthersScanScanning) {
              return _buildLoadingState(context, state);
            } else if (state is OthersScanSuccess) {
              return _buildSuccessState(context, state);
            } else if (state is OthersScanEmpty) {
              return _buildEmptyState(context, state);
            } else if (state is OthersScanError) {
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
                    colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    colorScheme.tertiaryContainer.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.tertiary.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.folder_off_outlined,
                size: 80,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            
            // Title with gradient effect
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  colorScheme.tertiary,
                  colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Text(
                'No Folder Selected',
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
                'Due to Android privacy rules, access to APKs, archives, and other files requires manual folder selection.',
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
                  colors: [colorScheme.tertiary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.tertiary.withValues(alpha: 0.3),
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
                    context.read<OthersScanCubit>().selectOthersFolder();
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
                          'Select Folder',
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
                color: colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: AppSize.paddingSmall),
                  Flexible(
                    child: Text(
                      'Choose Download or any folder with APKs',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.tertiary,
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

  Widget _buildLoadingState(BuildContext context, [OthersScanState? state]) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    String message = 'Loading...';
    if (state is OthersScanSelecting) {
      message = 'Opening folder picker...';
    } else if (state is OthersScanScanning) {
      message = 'Scanning files...';
    } else if (state is OthersScanLoading) {
      message = 'Loading files...';
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
                  colorScheme.tertiary.withValues(alpha: 0.1),
                  colorScheme.tertiary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.tertiary,
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
          if (state is OthersScanScanning) ...[
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

  Widget _buildSuccessState(BuildContext context, OthersScanSuccess state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (state.files.isEmpty) {
      return _buildEmptyState(context, OthersScanEmpty(folderName: state.folderName));
    }
    
    return Column(
      children: [
        // Header with file count
        Container(
          margin: const EdgeInsets.all(AppSize.paddingMedium),
          padding: const EdgeInsets.all(AppSize.paddingLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                colorScheme.secondaryContainer.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.tertiary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.tertiary.withValues(alpha: 0.08),
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
                      colorScheme.tertiary.withValues(alpha: 0.2),
                      colorScheme.tertiary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_special,
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: AppSize.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.files.length} files',
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
        
        // File list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingMedium),
            itemCount: state.files.length,
            itemBuilder: (context, index) {
              final file = state.files[index];
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
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      
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
                              Text('Opening ${file.name}...'),
                            ],
                          ),
                          backgroundColor: colorScheme.tertiary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      
                      // Open the file using method channel
                      try {
                        // Use the method channel to open the SAF file
                        const platform = MethodChannel('com.smarttools.storageanalyzer/native');
                        final result = await platform.invokeMethod('openDocument', {
                          'uri': file.uri,
                          'mimeType': file.mimeType,
                        });
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          if (result != true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Could not open file'),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error opening file: ${e.toString()}'),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSize.paddingMedium),
                      child: Row(
                        children: [
                          // File icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getColorForMimeType(file.mimeType, colorScheme)
                                      .withValues(alpha: 0.2),
                                  _getColorForMimeType(file.mimeType, colorScheme)
                                      .withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconForMimeType(file.mimeType, file.name),
                              color: _getColorForMimeType(file.mimeType, colorScheme),
                            ),
                          ),
                          const SizedBox(width: AppSize.paddingMedium),
                          
                          // File info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  SizeFormatter.formatBytes(file.size),
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
                              color: _getColorForMimeType(file.mimeType, colorScheme)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getFileExtension(file.name),
                              style: textTheme.labelSmall?.copyWith(
                                color: _getColorForMimeType(file.mimeType, colorScheme),
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

  Widget _buildEmptyState(BuildContext context, OthersScanEmpty state) {
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
                    colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.folder_open,
                size: 60,
                color: colorScheme.tertiary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            Text(
              'No Files Found',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              'No APKs or archives found in "${state.folderName}"',
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
                    context.read<OthersScanCubit>().selectOthersFolder();
                  },
                ),
                const SizedBox(width: AppSize.paddingMedium),
                _buildActionButton(
                  context,
                  icon: Icons.refresh,
                  label: 'Refresh',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.read<OthersScanCubit>().scanOthers(forceRefresh: true);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, OthersScanError state) {
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
                context.read<OthersScanCubit>().checkSavedFolder();
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
        foregroundColor: colorScheme.tertiary,
        side: BorderSide(color: colorScheme.tertiary.withValues(alpha: 0.3)),
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

  IconData _getIconForMimeType(String mimeType, String fileName) {
    // Check for APK files
    if (mimeType.contains('android') || fileName.toLowerCase().endsWith('.apk')) {
      return Icons.android;
    }
    // Archive files
    if (mimeType.contains('zip') || mimeType.contains('rar') || 
        mimeType.contains('compressed') || mimeType.contains('archive')) {
      return Icons.folder_zip;
    }
    // ISO/Disk images
    if (mimeType.contains('iso') || fileName.toLowerCase().endsWith('.iso')) {
      return Icons.album;
    }
    // Executable files
    if (mimeType.contains('executable') || fileName.toLowerCase().endsWith('.exe')) {
      return Icons.play_circle_outline;
    }
    // Database files
    if (mimeType.contains('sqlite') || fileName.toLowerCase().endsWith('.db')) {
      return Icons.storage;
    }
    // Torrent files
    if (mimeType.contains('torrent')) {
      return Icons.cloud_download;
    }
    return Icons.insert_drive_file;
  }

  Color _getColorForMimeType(String mimeType, ColorScheme colorScheme) {
    if (mimeType.contains('android') || mimeType.contains('apk')) {
      return Colors.green;
    }
    if (mimeType.contains('zip') || mimeType.contains('rar') || 
        mimeType.contains('compressed')) {
      return colorScheme.tertiary;
    }
    if (mimeType.contains('executable')) {
      return colorScheme.error;
    }
    if (mimeType.contains('sqlite') || mimeType.contains('database')) {
      return colorScheme.secondary;
    }
    return colorScheme.primary;
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return '.${parts.last.toUpperCase()}';
    }
    return '';
  }
}