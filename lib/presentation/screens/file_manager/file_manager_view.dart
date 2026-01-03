import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/file_manager_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/file_manager_header.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/file_tabs_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';

class FileManagerView extends StatefulWidget {
  const FileManagerView({super.key});

  @override
  State<FileManagerView> createState() => _FileManagerViewState();
}

class _FileManagerViewState extends State<FileManagerView> {
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<FileManagerCubit, FileManagerState>(
          listener: (context, state) {
            if (state is FileManagerDeleting) {
              _showDeletingDialog(context);
            } else if (state is FileManagerError) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error,
                ),
              );
            } else if (state is FileManagerLoaded) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
              setState(() {
                _isSelectionMode = state.selectedCount > 0;
              });
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                FileManagerHeader(
                  showSelectionActions:
                      state is FileManagerLoaded && state.selectedCount > 0,
                  onSelectAll: () {
                    HapticFeedback.lightImpact();
                    context.read<FileManagerCubit>().selectAll();
                  },
                  onClearSelection: () {
                    HapticFeedback.lightImpact();
                    context.read<FileManagerCubit>().clearSelection();
                  },
                ),
                if (state is! FileManagerLoading)
                  FileTabsWidget(
                    currentCategory: state is FileManagerLoaded
                        ? state.currentCategory
                        : FileCategory.all,
                    onTabChanged: (category) {
                      HapticFeedback.selectionClick();
                      context.read<FileManagerCubit>().changeCategory(
                        category,
                      );
                    },
                  ),
                Expanded(child: _buildContent(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeletingDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        content: Row(
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(width: 20),
            Text(
              "Deleting files...",
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FileManagerState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state is FileManagerLoading) {
      return const LoadingWidget();
    }

    if (state is FileManagerLoaded) {
      if (state.files.isEmpty) {
        return _buildEmptyState(context, state.currentCategory);
      }

      return ListView.builder(
        key: ValueKey(state.currentCategory),
        padding: const EdgeInsets.all(AppSize.paddingMedium),
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          final isSelected = state.selectedFileIds.contains(file.id);

          return _FileItemWidget(
            file: file,
            isSelected: isSelected,
            isSelectionMode: _isSelectionMode,
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<FileManagerCubit>().toggleFileSelection(
                file.id,
              );
            },
          );
        },
      );
    }

    if (state is FileManagerError) {
      return _buildErrorState(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(BuildContext context, FileCategory category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String message;
    IconData icon;
    switch (category) {
      case FileCategory.all:
        message = 'No files found';
        icon = Icons.folder_open_rounded;
        break;
      case FileCategory.large:
        message = 'No large files found';
        icon = Icons.sd_storage_rounded;
        break;
      case FileCategory.duplicates:
        message = 'No duplicate files found';
        icon = Icons.file_copy_rounded;
        break;
      case FileCategory.old:
        message = 'No old files found';
        icon = Icons.history_rounded;
        break;
      default:
        message = 'No files found in this category';
        icon = Icons.folder_off_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: colorScheme.primary.withValues(alpha: .5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
            ),
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha:  .1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading files',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Reload with default category
                context.read<FileManagerCubit>().loadFiles(FileCategory.all);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileItemWidget extends StatefulWidget {
  final dynamic file;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

  const _FileItemWidget({
    required this.file,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
  });

  @override
  State<_FileItemWidget> createState() => _FileItemWidgetState();
}

class _FileItemWidgetState extends State<_FileItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSize.paddingSmall),
        decoration: BoxDecoration(
          color: _isHovered
              ? colorScheme.surfaceContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSize.radiusMedium),
          border: Border.all(
            color: widget.isSelected
                ? colorScheme.primary
                : (_isHovered
                      ? colorScheme.outlineVariant
                      : Colors.transparent),
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (_isHovered || widget.isSelected)
              BoxShadow(
                color:
                    (widget.isSelected
                            ? colorScheme.primary
                            : colorScheme.shadow)
                        .withValues(alpha: isDark ? 0.2 : 0.1),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSize.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppSize.paddingMedium),
              child: Row(
                children: [
                  Transform.scale(
                    scale: widget.isSelected ? 1.1 : 1.0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getFileColor(
                              widget.file.extension,
                              colorScheme,
                            ).withValues(alpha: .15),
                            _getFileColor(
                              widget.file.extension,
                              colorScheme,
                            ).withValues(alpha: .05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getFileColor(
                            widget.file.extension,
                            colorScheme,
                          ).withValues(alpha: .2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getFileIcon(widget.file.extension),
                        color: _getFileColor(
                          widget.file.extension,
                          colorScheme,
                        ),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.file.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: widget.isSelected
                                ? colorScheme.primary
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.storage_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              SizeFormatter.formateBytes(
                                widget.file.sizeInBytes,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTimeAgo(widget.file.lastModified),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.isSelected)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    )
                  else if (widget.isSelectionMode)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();

    // Images
    if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.svg',
      '.ico',
    ].contains(ext)) {
      return Icons.image_rounded;
    }
    // Videos
    else if ([
      '.mp4',
      '.avi',
      '.mkv',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
    ].contains(ext)) {
      return Icons.video_file_rounded;
    }
    // Audio
    else if ([
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.ogg',
      '.wma',
      '.m4a',
    ].contains(ext)) {
      return Icons.audio_file_rounded;
    }
    // Documents
    else if (['.pdf'].contains(ext)) {
      return Icons.picture_as_pdf_rounded;
    } else if (['.doc', '.docx', '.txt', '.odt'].contains(ext)) {
      return Icons.description_rounded;
    } else if (['.xls', '.xlsx', '.csv'].contains(ext)) {
      return Icons.table_chart_rounded;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Icons.slideshow_rounded;
    }
    // Archives
    else if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(ext)) {
      return Icons.folder_zip_rounded;
    }
    // Apps
    else if (['.apk', '.xapk', '.aab'].contains(ext)) {
      return Icons.android_rounded;
    }
    // Code
    else if ([
      '.xml',
      '.json',
      '.html',
      '.css',
      '.js',
      '.dart',
      '.java',
      '.kt',
    ].contains(ext)) {
      return Icons.code_rounded;
    } else {
      return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String extension, ColorScheme colorScheme) {
    final ext = extension.toLowerCase();

    // Use theme-aware colors
    if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.svg',
      '.ico',
    ].contains(ext)) {
      return colorScheme.tertiary;
    } else if ([
      '.mp4',
      '.avi',
      '.mkv',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
    ].contains(ext)) {
      return colorScheme.error;
    } else if ([
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.ogg',
      '.wma',
      '.m4a',
    ].contains(ext)) {
      return colorScheme.secondary;
    } else if ([
      '.pdf',
      '.doc',
      '.docx',
      '.txt',
      '.odt',
      '.xls',
      '.xlsx',
      '.csv',
      '.ppt',
      '.pptx',
    ].contains(ext)) {
      return colorScheme.primary;
    } else if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(ext)) {
      return Color.alphaBlend(
        colorScheme.tertiary.withValues(alpha: .5),
        colorScheme.surface,
      );
    } else if (['.apk', '.xapk', '.aab'].contains(ext)) {
      return Color.alphaBlend(
        colorScheme.primary.withValues(alpha: .7),
        colorScheme.surface,
      );
    } else {
      return colorScheme.primary;
    }
  }
}
