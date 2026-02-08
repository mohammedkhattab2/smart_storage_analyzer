import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/services/saf_media_scanner_service.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/presentation/cubits/media_scan/media_scan_cubit.dart';
import 'package:smart_storage_analyzer/presentation/mappers/category_ui_mapper.dart';
import 'package:smart_storage_analyzer/core/services/content_uri_service.dart';

/// Screen for SAF-based media scanning.
/// 
/// Handles three states:
/// 1. No folder selected - shows prompt to select folder
/// 2. Scanning - shows loading animation
/// 3. Results - shows scanned files with statistics
class MediaScannerScreen extends StatelessWidget {
  final MediaType mediaType;
  final String categoryName;

  const MediaScannerScreen({
    super.key,
    required this.mediaType,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MediaScanCubit(mediaType: mediaType)..initialize(),
      child: _MediaScannerView(
        mediaType: mediaType,
        categoryName: categoryName,
      ),
    );
  }
}

class _MediaScannerView extends StatelessWidget {
  final MediaType mediaType;
  final String categoryName;

  const _MediaScannerView({
    required this.mediaType,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = _getCategoryColor();
    final categoryIcon = _getCategoryIcon();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<MediaScanCubit, MediaScanState>(
            builder: (context, state) {
              if (state is MediaScanLoaded) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'change_folder':
                        context.read<MediaScanCubit>().changeFolder();
                        break;
                      case 'rescan':
                        context.read<MediaScanCubit>().rescan();
                        break;
                      case 'clear_folder':
                        context.read<MediaScanCubit>().clearFolder();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'change_folder',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open),
                          SizedBox(width: 12),
                          Text('Change Folder'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rescan',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 12),
                          Text('Rescan'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_folder',
                      child: Row(
                        children: [
                          Icon(Icons.clear),
                          SizedBox(width: 12),
                          Text('Clear Selection'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<MediaScanCubit, MediaScanState>(
        builder: (context, state) {
          if (state is MediaScanInitial || state is MediaScanNoFolder) {
            return _buildNoFolderState(context, categoryColor, categoryIcon);
          }
          
          if (state is MediaScanScanning) {
            return _buildScanningState(context, state, categoryColor, categoryIcon);
          }
          
          if (state is MediaScanLoaded) {
            return _buildLoadedState(context, state, categoryColor, categoryIcon);
          }
          
          if (state is MediaScanError) {
            return _buildErrorState(context, state, categoryColor, categoryIcon);
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNoFolderState(
    BuildContext context,
    Color categoryColor,
    IconData categoryIcon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    categoryColor.withValues(alpha: 0.2),
                    categoryColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: categoryColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 48,
                    color: categoryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            
            // Title
            Text(
              'Select a Folder to Scan',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingMedium),
            
            // Description
            Container(
              padding: const EdgeInsets.all(AppSize.paddingLarge),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getDescriptionText(),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge * 1.5),
            
            // Select Folder Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.3),
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
                    context.read<MediaScanCubit>().selectAndScanFolder();
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingXLarge * 1.5,
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
            
            // Hint
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.paddingLarge,
                vertical: AppSize.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: categoryColor,
                  ),
                  const SizedBox(width: AppSize.paddingSmall),
                  Text(
                    _getHintText(),
                    style: textTheme.bodySmall?.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w500,
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

  Widget _buildScanningState(
    BuildContext context,
    MediaScanScanning state,
    Color categoryColor,
    IconData categoryIcon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated scanning indicator
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  categoryColor.withValues(alpha: 0.1),
                  categoryColor.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  ),
                ),
                Icon(
                  categoryIcon,
                  size: 40,
                  color: categoryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          
          Text(
            'Scanning $categoryName...',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.folderName != null) ...[
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              state.folderName!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSize.paddingLarge),
          
          Text(
            'This may take a moment...',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    MediaScanLoaded state,
    Color categoryColor,
    IconData categoryIcon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await context.read<MediaScanCubit>().rescan();
      },
      color: categoryColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Statistics Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSize.paddingLarge),
              padding: const EdgeInsets.all(AppSize.paddingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withValues(alpha: 0.1),
                    categoryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSize.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.folderName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.fileCount} files • ${SizeFormatter.formatBytes(state.totalSize)}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Largest Files Section
          if (state.largestFiles.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSize.paddingLarge,
                  vertical: AppSize.paddingSmall,
                ),
                child: Text(
                  'Largest Files',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final file = state.largestFiles[index];
                  return _buildFileItem(context, file, categoryColor, index);
                },
                childCount: state.largestFiles.length,
              ),
            ),
          ],

          // All Files Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.paddingLarge,
                vertical: AppSize.paddingSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Files (${state.fileCount})',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (state.files.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        if (state.isSelectionMode) {
                          context.read<MediaScanCubit>().clearSelection();
                        } else {
                          context.read<MediaScanCubit>().selectAll();
                        }
                      },
                      icon: Icon(
                        state.isSelectionMode
                            ? Icons.deselect
                            : Icons.select_all,
                        size: 18,
                      ),
                      label: Text(
                        state.isSelectionMode ? 'Deselect All' : 'Select All',
                      ),
                    ),
                ],
              ),
            ),
          ),

          // File List
          if (state.files.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSize.paddingXLarge * 2),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_off_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSize.paddingMedium),
                      Text(
                        'No ${categoryName.toLowerCase()} found in this folder',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final file = state.files[index];
                  final isSelected = state.selectedFileIds.contains(file.id);
                  return _buildFileItem(
                    context,
                    file,
                    categoryColor,
                    index,
                    isSelected: isSelected,
                    isSelectionMode: state.isSelectionMode,
                  );
                },
                childCount: state.files.length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    ScannedMediaFile file,
    Color categoryColor,
    int index, {
    bool isSelected = false,
    bool isSelectionMode = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSize.paddingLarge,
        vertical: AppSize.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? categoryColor.withValues(alpha: 0.1)
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? categoryColor.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isSelectionMode) {
              context.read<MediaScanCubit>().toggleFileSelection(file.id);
            } else {
              // Open file using native content URI handler
              _openMediaFile(context, file);
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            context.read<MediaScanCubit>().toggleFileSelection(file.id);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSize.paddingMedium),
            child: Row(
              children: [
                // Thumbnail/Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(file.extension),
                    color: categoryColor,
                    size: 24,
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
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
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
                
                // Selection indicator
                if (isSelectionMode)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? categoryColor
                          : colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: isSelected
                            ? categoryColor
                            : colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: colorScheme.onPrimary,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    MediaScanError state,
    Color categoryColor,
    IconData categoryIcon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSize.paddingLarge),
            Text(
              'Something went wrong',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSize.paddingMedium),
            Text(
              state.message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            ElevatedButton.icon(
              onPressed: () {
                context.read<MediaScanCubit>().selectAndScanFolder();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (mediaType) {
      case MediaType.images:
        return CategoryUIMapper.getColor('images');
      case MediaType.videos:
        return CategoryUIMapper.getColor('videos');
      case MediaType.audio:
        return CategoryUIMapper.getColor('audio');
    }
  }

  IconData _getCategoryIcon() {
    switch (mediaType) {
      case MediaType.images:
        return Icons.image_rounded;
      case MediaType.videos:
        return Icons.video_library_rounded;
      case MediaType.audio:
        return Icons.audiotrack_rounded;
    }
  }

  String _getDescriptionText() {
    switch (mediaType) {
      case MediaType.images:
        return 'Select a folder like DCIM or Pictures to scan for images. '
            'We\'ll analyze the folder and show you all photos with their sizes.';
      case MediaType.videos:
        return 'Select a folder like Movies or DCIM to scan for videos. '
            'We\'ll find all video files and show you the largest ones.';
      case MediaType.audio:
        return 'Select a folder like Music or Downloads to scan for audio files. '
            'We\'ll discover all your music and audio recordings.';
    }
  }

  String _getHintText() {
    switch (mediaType) {
      case MediaType.images:
        return 'Try DCIM, Pictures, or Download';
      case MediaType.videos:
        return 'Try Movies, DCIM, or Download';
      case MediaType.audio:
        return 'Try Music, Download, or Recordings';
    }
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    
    // Images
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'].contains(ext)) {
      return Icons.image_rounded;
    }
    
    // Videos
    if (['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(ext)) {
      return Icons.video_file_rounded;
    }
    
    // Audio
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a'].contains(ext)) {
      return Icons.audio_file_rounded;
    }
    
    return Icons.insert_drive_file_rounded;
  }

  /// Open media file using content URI service
  void _openMediaFile(BuildContext context, ScannedMediaFile file) async {
    HapticFeedback.lightImpact();
    
    try {
      final success = await ContentUriService.openContentUri(
        file.uri,
        mimeType: file.mimeType,
      );
      
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open ${file.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open ${file.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}