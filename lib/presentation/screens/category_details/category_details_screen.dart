import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/media_viewer/media_viewer_screen.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/error_widget.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final Category category;

  const CategoryDetailsScreen({Key? key, required this.category})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CategoryDetailsCubit>()..loadCategoryFiles(category),
      child: _CategoryDetailsView(category: category),
    );
  }
}

class _CategoryDetailsView extends StatelessWidget {
  final Category category;

  const _CategoryDetailsView({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            Text(
              category.name,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
              builder: (context, state) {
                if (state is CategoryDetailsLoaded) {
                  return Text(
                    '${state.files.length} files â€¢ ${SizeFormatter.formateBytes(state.totalSize)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Text(
                  '${category.fileCount} files â€¢ ${SizeFormatter.formateBytes(category.sizeInBytes.toInt())}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha:  .2),
          ),
        ),
      ),
      body: BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
        builder: (context, state) {
          if (state is CategoryDetailsLoading) {
            return const Center(child: LoadingWidget());
          }

          if (state is CategoryDetailsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSize.paddingLarge),
                child: ErrorT(
                  message: state.message,
                  onRetry: () {
                    context.read<CategoryDetailsCubit>().loadCategoryFiles(
                      category,
                    );
                  },
                ),
              ),
            );
          }

          if (state is CategoryDetailsLoaded) {
            if (state.files.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(category.name),
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(alpha:  .3),
                    ),
                    const SizedBox(height: AppSize.paddingLarge),
                    Text(
                      'No ${category.name} found',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSize.paddingSmall),
                    Text(
                      'Files will appear here when detected',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha:  .7,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainer,
              onRefresh: () async {
                await context.read<CategoryDetailsCubit>().refresh(category);
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSize.paddingMedium,
                  vertical: AppSize.paddingMedium,
                ),
                itemCount: state.files.length,
                itemBuilder: (context, index) {
                  final file = state.files[index];
                  return _FileListItem(
                    file: file,
                    category: category,
                    onTap: () {
                      // Navigate to media viewer for images and videos
                      if (_isMediaFile(file)) {
                        final mediaFiles = state.files
                            .where((f) => _isMediaFile(f))
                            .toList();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MediaViewerScreen(
                              file: file,
                              allFiles: mediaFiles,
                            ),
                          ),
                        );
                      } else {
                        // For non-media files, show a snackbar or different viewer
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening ${file.name}'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSize.radiusSmall,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  bool _isMediaFile(FileItem file) {
    final extension = file.extension.toLowerCase();
    return [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.mp4',
      '.avi',
      '.mov',
      '.mkv',
    ].contains(extension);
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'images':
      case 'image':
        return Icons.image_rounded;
      case 'videos':
      case 'video':
        return Icons.video_library_rounded;
      case 'audio':
      case 'music':
        return Icons.library_music_rounded;
      case 'documents':
      case 'document':
        return Icons.folder_rounded;
      case 'apps':
      case 'applications':
        return Icons.apps_rounded;
      default:
        return Icons.folder_open_rounded;
    }
  }
}

class _FileListItem extends StatelessWidget {
  final FileItem file;
  final Category category;
  final VoidCallback onTap;

  const _FileListItem({
    required this.file,
    required this.category,
    required this.onTap,
  });

  IconData _getFileIcon() {
    final extension = file.extension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return Icons.image_rounded;
    } else if (['.mp4', '.avi', '.mov', '.mkv'].contains(extension)) {
      return Icons.video_file_rounded;
    } else if (['.mp3', '.wav', '.flac', '.m4a'].contains(extension)) {
      return Icons.audio_file_rounded;
    } else if (['.pdf', '.doc', '.txt', '.xlsx'].contains(extension)) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSize.paddingSmall),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSize.paddingMedium),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha:  .15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getFileIcon(), color: category.color, size: 24),
                ),
                const SizedBox(width: AppSize.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${SizeFormatter.formateBytes(file.sizeInBytes)} â€¢ ${_formatDate(file.lastModified)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    }
    return '${(difference.inDays / 365).floor()} years ago';
  }
}
