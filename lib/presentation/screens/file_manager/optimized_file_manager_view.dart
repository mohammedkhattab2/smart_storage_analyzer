import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/optimized_file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/file_tabs_widget.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/skeleton_loader.dart';
import 'package:smart_storage_analyzer/presentation/screens/media_viewer/in_app_media_viewer_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

/// Optimized file manager view with lazy loading and performance improvements
class OptimizedFileManagerView extends StatefulWidget {
  const OptimizedFileManagerView({super.key});

  @override
  State<OptimizedFileManagerView> createState() => _OptimizedFileManagerViewState();
}

class _OptimizedFileManagerViewState extends State<OptimizedFileManagerView> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more when user scrolls to 80% of the list
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore) {
        _isLoadingMore = true;
        context.read<OptimizedFileManagerCubit>().loadMoreFiles();
        Future.delayed(const Duration(milliseconds: 500), () {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha:  0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<OptimizedFileManagerCubit, OptimizedFileManagerState>(
            listener: _handleStateChanges,
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeader(context, state),
                  if (state is! FileManagerLoading)
                    _buildTabs(context, state),
                  Expanded(child: _buildContent(context, state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, OptimizedFileManagerState state) {
    if (state is FileManagerDeleting) {
      _showDeletingDialog(context, state);
    } else if (state is FileManagerError) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showErrorSnackBar(context, state.message);
    } else if (state is FileManagerLoaded) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildHeader(BuildContext context, OptimizedFileManagerState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final showSelectionActions = state is FileManagerLoaded && state.selectedCount > 0;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha:  0.9),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha:  0.05),
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
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha:  0.1),
            ),
            child: Icon(
              Icons.folder_rounded,
              size: 24,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File Manager',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state is FileManagerLoaded)
                  Text(
                    '${state.totalCount} files',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (showSelectionActions) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<OptimizedFileManagerCubit>().toggleSelectAll();
              },
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<OptimizedFileManagerCubit>().clearSelection();
              },
              tooltip: 'Clear Selection',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, OptimizedFileManagerState state) {
    final currentCategory = state is FileManagerLoaded 
        ? state.currentCategory 
        : FileCategory.all;

    return FileTabsWidget(
      currentCategory: currentCategory,
      onTabChanged: (category) {
        HapticFeedback.selectionClick();
        context.read<OptimizedFileManagerCubit>().changeCategory(category);
      },
    );
  }

  Widget _buildContent(BuildContext context, OptimizedFileManagerState state) {
    if (state is FileManagerLoading) {
      return _buildLoadingState(context);
    }

    if (state is FileManagerLoaded) {
      if (state.files.isEmpty) {
        return _buildEmptyState(context, state.currentCategory);
      }

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await context.read<OptimizedFileManagerCubit>().refresh();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: AppSize.paddingMedium,
                right: AppSize.paddingMedium,
                top: AppSize.paddingMedium,
                bottom: state.selectedCount > 0 ? 80 : AppSize.paddingMedium,
              ),
              itemCount: state.files.length + (state.hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index >= state.files.length) {
                  return _buildLoadMoreIndicator();
                }

                final file = state.files[index];
                final isSelected = state.selectedFileIds.contains(file.id);

                return _FileItemWidget(
                  file: file,
                  isSelected: isSelected,
                  onTap: () => _handleFileTap(context, file, state),
                  onLongPress: () => _handleFileLongPress(context, file.id),
                );
              },
            ),
          ),
          if (state.selectedCount > 0)
            _buildSelectionBottomBar(context, state),
        ],
      );
    }

    if (state is FileManagerError) {
      return _buildErrorState(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState(BuildContext context) {
    return const SkeletonListLoader(
      itemCount: 10,
      itemHeight: 72,
      padding: EdgeInsets.all(AppSize.paddingMedium),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppSize.paddingLarge),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FileCategory category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String message = _getEmptyMessage(category);
    IconData icon = _getEmptyIcon(category);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: colorScheme.primary.withValues(alpha:  0.3),
            ),
            const SizedBox(height: AppSize.paddingLarge),
            Text(
              message,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              'Try selecting a different category',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FileManagerError state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSize.paddingLarge),
            Text(
              'Error loading files',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              state.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<OptimizedFileManagerCubit>().loadFiles(
                  state.lastCategory ?? FileCategory.all,
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBottomBar(
    BuildContext context,
    FileManagerLoaded state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSize.paddingMedium),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha:  0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.selectedCount} selected',
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      SizeFormatter.formatBytes(state.selectedTotalSize),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareFiles(context, state),
                tooltip: 'Share',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: colorScheme.error,
                ),
                onPressed: () => _confirmDelete(context, state),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileTap(
    BuildContext context,
    dynamic file,
    FileManagerLoaded state,
  ) async {
    HapticFeedback.lightImpact();
    
    if (state.selectedCount > 0) {
      // In selection mode, toggle selection
      context.read<OptimizedFileManagerCubit>().toggleFileSelection(file.id);
    } else {
      // Open file
      if (_isMediaFile(file)) {
        final mediaFiles = state.files.where((f) => _isMediaFile(f)).toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InAppMediaViewerScreen(
              file: file,
              allFiles: mediaFiles,
            ),
          ),
        );
      } else {
        try {
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done && context.mounted) {
            _showErrorSnackBar(context, 'Cannot open ${file.name}');
          }
        } catch (e) {
          if (context.mounted) {
            _showErrorSnackBar(context, 'Failed to open ${file.name}');
          }
        }
      }
    }
  }

  void _handleFileLongPress(BuildContext context, String fileId) {
    HapticFeedback.mediumImpact();
    context.read<OptimizedFileManagerCubit>().toggleFileSelection(fileId);
  }

  void _shareFiles(BuildContext context, FileManagerLoaded state) async {
    HapticFeedback.lightImpact();
    
    if (state.selectedFiles.isEmpty) return;

    try {
      final xFiles = state.selectedFiles
          .map((f) => XFile(f.path))
          .toList();
      await Share.shareXFiles(xFiles);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to share files');
      }
    }
  }

  void _confirmDelete(BuildContext context, FileManagerLoaded state) {
    HapticFeedback.mediumImpact();
    
    final colorScheme = Theme.of(context).colorScheme;
    final count = state.selectedCount;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $count ${count == 1 ? 'File' : 'Files'}?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete the selected files?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<OptimizedFileManagerCubit>().deleteSelectedFiles();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeletingDialog(BuildContext context, FileManagerDeleting state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: state.progress),
            const SizedBox(height: AppSize.paddingMedium),
            Text(state.message),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getEmptyMessage(FileCategory category) {
    switch (category) {
      case FileCategory.all:
        return 'No files found';
      case FileCategory.large:
        return 'No large files found';
      case FileCategory.duplicates:
        return 'No duplicate files found';
      case FileCategory.old:
        return 'No old files found';
      default:
        return 'No files found in this category';
    }
  }

  IconData _getEmptyIcon(FileCategory category) {
    switch (category) {
      case FileCategory.all:
        return Icons.folder_open;
      case FileCategory.large:
        return Icons.sd_storage;
      case FileCategory.duplicates:
        return Icons.file_copy;
      case FileCategory.old:
        return Icons.history;
      default:
        return Icons.folder_off;
    }
  }

  bool _isMediaFile(dynamic file) {
    final ext = file.extension.toLowerCase();
    const mediaExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp',
      '.mp4', '.avi', '.mov', '.mkv', '.webm',
      '.mp3', '.wav', '.flac', '.aac', '.ogg',
    ];
    return mediaExtensions.contains(ext);
  }
}

/// Optimized file item widget with performance improvements
class _FileItemWidget extends StatelessWidget {
  final dynamic file;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FileItemWidget({
    required this.file,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSize.paddingSmall),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha:  0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppSize.paddingMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // File icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileColor(colorScheme).withValues(alpha:  0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(),
                    color: _getFileColor(colorScheme),
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
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.storage,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            SizeFormatter.formatBytes(file.sizeInBytes),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(file.lastModified),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.circle_outlined,
                    color: colorScheme.outline,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    final ext = file.extension.toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(ext)) {
      return Icons.image;
    } else if (['.mp4', '.avi', '.mkv', '.mov'].contains(ext)) {
      return Icons.video_file;
    } else if (['.mp3', '.wav', '.flac', '.aac'].contains(ext)) {
      return Icons.audio_file;
    } else if (['.pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['.doc', '.docx', '.txt'].contains(ext)) {
      return Icons.description;
    } else if (['.zip', '.rar', '.7z'].contains(ext)) {
      return Icons.folder_zip;
    } else if (['.apk'].contains(ext)) {
      return Icons.android;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(ColorScheme colorScheme) {
    final ext = file.extension.toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif'].contains(ext)) {
      return colorScheme.tertiary;
    } else if (['.mp4', '.avi', '.mkv'].contains(ext)) {
      return colorScheme.error;
    } else if (['.mp3', '.wav'].contains(ext)) {
      return colorScheme.secondary;
    } else if (['.pdf', '.doc', '.docx'].contains(ext)) {
      return colorScheme.primary;
    } else if (['.apk'].contains(ext)) {
      return Colors.green;
    } else {
      return colorScheme.primary;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years${years == 1 ? ' year' : ' years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months${months == 1 ? ' month' : ' months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}${difference.inDays == 1 ? ' day' : ' days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${difference.inHours == 1 ? ' hour' : ' hours'} ago';
    } else {
      return 'Just now';
    }
  }
}