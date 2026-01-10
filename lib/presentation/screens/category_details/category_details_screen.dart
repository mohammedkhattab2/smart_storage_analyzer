import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/category_details/category_details_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/media_viewer/in_app_media_viewer_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:smart_storage_analyzer/core/services/content_uri_service.dart';
import 'package:smart_storage_analyzer/presentation/mappers/category_ui_mapper.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final Category category;

  const CategoryDetailsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return _CategoryDetailsView(category: category);
  }
}

class _CategoryDetailsView extends StatefulWidget {
  final Category category;

  const _CategoryDetailsView({required this.category});

  @override
  State<_CategoryDetailsView> createState() => _CategoryDetailsViewState();
}

class _CategoryDetailsViewState extends State<_CategoryDetailsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryDetailsCubit>().loadCategoryFiles(widget.category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: _buildMagicalAppBar(context, colorScheme, textTheme, isDark),
      body: Stack(
        children: [
          // Magical gradient background
          _buildMagicalBackground(colorScheme, isDark),

          // Main content
          SafeArea(
            child: BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
              builder: (context, state) {
                if (state is CategoryDetailsLoading) {
                  return _buildMagicalLoading(colorScheme);
                }

                if (state is CategoryDetailsError) {
                  return _buildMagicalError(context, state, colorScheme);
                }

                if (state is CategoryDetailsLoaded) {
                  if (state.files.isEmpty) {
                    return _buildMagicalEmptyState(colorScheme, textTheme);
                  }

                  return Column(
                    children: [
                      if (state.isSelectionMode)
                        _buildSelectionInfoBar(
                          state,
                          colorScheme,
                          textTheme,
                        ),
                      Expanded(
                        child: _buildFilesList(
                          context,
                          state,
                          colorScheme,
                          isDark,
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMagicalAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface.withValues(alpha: .8),
                  colorScheme.surface.withValues(alpha: .6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: .2),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                CategoryUIMapper.getColor(widget.category.id),
                CategoryUIMapper.getColor(widget.category.id).withValues(
                  red: math.min(1.0, CategoryUIMapper.getColor(widget.category.id).r * 1.2),
                  green: math.min(1.0, CategoryUIMapper.getColor(widget.category.id).g * 1.2),
                  blue: math.min(1.0, CategoryUIMapper.getColor(widget.category.id).b * 1.2),
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              widget.category.name,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
            builder: (context, state) {
              if (state is CategoryDetailsLoaded) {
                return Text(
                  '${state.files.length} files • ${SizeFormatter.formatBytes(state.totalSize)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return Text(
                '${widget.category.fileCount} files • ${SizeFormatter.formatBytes(widget.category.sizeInBytes.toInt())}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
          builder: (context, state) {
            final isSelectionMode = state is CategoryDetailsLoaded && state.isSelectionMode;
            final hasSelection = state is CategoryDetailsLoaded && state.hasSelection;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selection Mode Toggle
                Container(
                  margin: const EdgeInsets.all(8),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isSelectionMode
                                  ? CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .3)
                                  : colorScheme.surfaceContainerHighest.withValues(
                                      alpha: isDark ? .3 : .6,
                                    ),
                              isSelectionMode
                                  ? CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .2)
                                  : colorScheme.surfaceContainer.withValues(
                                      alpha: isDark ? .2 : .4,
                                    ),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelectionMode
                                ? CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .3)
                                : colorScheme.outline.withValues(alpha: .15),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            context.read<CategoryDetailsCubit>().toggleSelectionMode();
                            HapticFeedback.lightImpact();
                          },
                          icon: Icon(
                            isSelectionMode ? Icons.done : Icons.checklist,
                            size: 18,
                            color: isSelectionMode
                                ? CategoryUIMapper.getColor(widget.category.id)
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Share Selected Button
                if (isSelectionMode && hasSelection)
                  Container(
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer.withValues(alpha: .4),
                                colorScheme.primaryContainer.withValues(alpha: .3),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => _shareSelectedFiles(context),
                            icon: Icon(
                              Icons.share,
                              size: 18,
                              color: CategoryUIMapper.getColor(widget.category.id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Delete Selected Button
                if (isSelectionMode && hasSelection)
                  Container(
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.errorContainer.withValues(alpha: .4),
                                colorScheme.errorContainer.withValues(alpha: .3),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: .3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => _deleteSelectedFiles(context),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectionInfoBar(
    CategoryDetailsLoaded state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSize.paddingMedium,
        vertical: AppSize.paddingSmall,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSize.paddingMedium,
        vertical: AppSize.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${state.selectedCount} selected',
                style: textTheme.bodyMedium?.copyWith(
                  color: CategoryUIMapper.getColor(widget.category.id),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.selectedSize > 0)
                Text(
                  SizeFormatter.formatBytes(state.selectedSize),
                  style: textTheme.bodySmall?.copyWith(
                    color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .8),
                  ),
                ),
            ],
          ),
          TextButton(
            onPressed: () {
              context.read<CategoryDetailsCubit>().toggleAllFiles();
            },
            child: Text(
              state.selectedFileIds.length == state.files.length
                  ? 'Deselect All'
                  : 'Select All',
              style: TextStyle(
                color: CategoryUIMapper.getColor(widget.category.id),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalBackground(ColorScheme colorScheme, bool isDark) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.5, -0.5),
              radius: 1.5,
              colors: [
                CategoryUIMapper.getColor(widget.category.id).withValues(alpha: isDark ? .08 : .15),
                colorScheme.surface,
                colorScheme.surfaceContainer.withValues(
                  alpha: isDark ? .3 : .5,
                ),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Floating orbs
        Positioned(
          top: 100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .1),
                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          left: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: .08),
                  colorScheme.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Custom pattern painter
        CustomPaint(
          size: Size.infinite,
          painter: _CategoryBackgroundPainter(
            color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .03),
            secondaryColor: colorScheme.primary.withValues(alpha: .02),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalLoading(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .15),
                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: 0),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      CategoryUIMapper.getColor(widget.category.id),
                      CategoryUIMapper.getColor(widget.category.id).withValues(
                        red: math.min(1.0, CategoryUIMapper.getColor(widget.category.id).r * 0.8),
                        green: math.min(1.0, CategoryUIMapper.getColor(widget.category.id).g * 0.8),
                        blue: math.min(1.0, CategoryUIMapper.getColor(widget.category.id).b * 0.8),
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading ${widget.category.name}...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalError(
    BuildContext context,
    CategoryDetailsError state,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.errorContainer.withValues(alpha: .15),
                colorScheme.errorContainer.withValues(alpha: .05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: .2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.error.withValues(alpha: .1),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Files',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  context.read<CategoryDetailsCubit>().loadCategoryFiles(
                    widget.category,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .1),
                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                      colorScheme.surfaceContainer.withValues(alpha: .3),
                    ],
                  ),
                  border: Border.all(
                    color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getCategoryIcon(widget.category.name),
                  size: 48,
                  color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSize.paddingLarge),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [colorScheme.onSurface, colorScheme.onSurfaceVariant],
            ).createShader(bounds),
            child: Text(
              'No ${widget.category.name} found',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSize.paddingSmall),
          Text(
            'Files will appear here when detected',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(
    BuildContext context,
    CategoryDetailsLoaded state,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final cubit = context.read<CategoryDetailsCubit>();
    
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        // Load more files when user scrolls near the bottom
        if (scrollInfo is ScrollEndNotification &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          // Load more files if not already loading
          cubit.loadMoreFiles();
        }
        return false;
      },
      child: RefreshIndicator(
        color: CategoryUIMapper.getColor(widget.category.id),
        backgroundColor: colorScheme.surface,
        strokeWidth: 3,
        displacement: 80,
        onRefresh: () async {
          await cubit.refresh(widget.category);
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSize.paddingMedium,
            vertical: AppSize.paddingMedium,
          ),
          itemCount: state.files.length + 1, // +1 for loading indicator
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom if loading more
            if (index == state.files.length) {
              return BlocBuilder<CategoryDetailsCubit, CategoryDetailsState>(
                builder: (context, currentState) {
                  // Check if we're loading more files
                  if (currentState is CategoryDetailsLoaded &&
                      cubit.isLoadingMore) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CategoryUIMapper.getColor(widget.category.id),
                        ),
                      ),
                    );
                  }
                  // Return empty container if not loading or no more data
                  return const SizedBox.shrink();
                },
              );
            }
            final file = state.files[index];
            
            // Debug category info
            developer.log('[LIST] Creating item for: ${file.name}', name: 'CategoryDetails');
            developer.log('[LIST] Category name: ${widget.category.name}', name: 'CategoryDetails');
            developer.log('[LIST] File extension: ${file.extension}', name: 'CategoryDetails');
            
            return _MagicalFileListItem(
            file: file,
            category: widget.category,
            index: index,
            isDark: isDark,
            isSelected: state.isFileSelected(file.id),
            selectionMode: state.isSelectionMode,
            onTap: () async {
              developer.log('[TAP HANDLER] onTap called for: ${file.name}', name: 'CategoryDetails');
              developer.log('[TAP HANDLER] Selection mode: ${state.isSelectionMode}', name: 'CategoryDetails');
              
              if (state.isSelectionMode) {
                developer.log('[TAP HANDLER] In selection mode, selecting file', name: 'CategoryDetails');
                context.read<CategoryDetailsCubit>().selectFile(file.id);
              } else {
                // Debug logging
                developer.log('[TAP HANDLER] Not in selection mode, determining action', name: 'CategoryDetails');
                developer.log('[TAP HANDLER] File: ${file.name}', name: 'CategoryDetails');
                developer.log('[TAP HANDLER] Extension: ${file.extension}', name: 'CategoryDetails');
                developer.log('[TAP HANDLER] Category: ${widget.category.name}', name: 'CategoryDetails');
                developer.log('[TAP HANDLER] Is media file check: ${_isMediaFile(file)}', name: 'CategoryDetails');
                
                // Open file based on type
                if (_isMediaFile(file)) {
                  developer.log('[TAP HANDLER] Opening as media file in viewer', name: 'CategoryDetails');
                  // Images, videos and audio open in in-app viewer
                  final mediaFiles = state.files
                      .where((f) => _isMediaFile(f))
                      .toList();
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
                  developer.log('[TAP HANDLER] Opening document dialog for: ${file.name}', name: 'CategoryDetails');
                  // Documents - show dialog with button to open (like audio does)
                  _showDocumentOpenDialog(context, file);
                }
              }
            },
            onLongPress: () {
              if (!state.isSelectionMode) {
                context.read<CategoryDetailsCubit>().toggleSelectionMode();
                context.read<CategoryDetailsCubit>().selectFile(file.id);
              }
            },
            );
          },
        ),
      ),
    );
  }


  void _shareFile(FileItem file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], subject: file.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.radiusSmall),
            ),
          ),
        );
      }
    }
  }

  void _shareSelectedFiles(BuildContext context) async {
    final selectedFiles = context.read<CategoryDetailsCubit>().getSelectedFiles();
    if (selectedFiles.isEmpty) return;

    final xFiles = selectedFiles.map((file) => XFile(file.path)).toList();

    try {
      await Share.shareXFiles(xFiles);
      
      // Exit selection mode after sharing
      if (context.mounted) {
        context.read<CategoryDetailsCubit>().clearSelection();
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          'Failed to share files: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _deleteSelectedFiles(BuildContext context) async {
    final cubit = context.read<CategoryDetailsCubit>();
    final selectedFiles = cubit.getSelectedFiles();
    if (selectedFiles.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Selected Files'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${selectedFiles.length} files?'),
            const SizedBox(height: 12),
            Text(
              'Total size: ${SizeFormatter.formatBytes(
                selectedFiles.fold<int>(
                  0,
                  (sum, file) => sum + file.sizeInBytes,
                ),
              )}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading snackbar
    if (context.mounted) {
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
            Text('Deleting ${selectedFiles.length} files...'),
          ],
        ),
        backgroundColor: CategoryUIMapper.getColor(widget.category.id),
        duration: const Duration(seconds: 30),
        ),
      );
    }

    try {
      await cubit.deleteSelectedFiles();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar('${selectedFiles.length} files deleted successfully');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar(
          'Failed to delete files: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : CategoryUIMapper.getColor(widget.category.id),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.radiusSmall),
        ),
      ),
    );
  }

  String? _getMimeTypeForDocument(String extension) {
    final ext = extension.toLowerCase();
    final mimeTypes = {
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls': 'application/vnd.ms-excel',
      '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      '.ppt': 'application/vnd.ms-powerpoint',
      '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      '.txt': 'text/plain',
      '.rtf': 'application/rtf',
      '.odt': 'application/vnd.oasis.opendocument.text',
      '.ods': 'application/vnd.oasis.opendocument.spreadsheet',
      '.odp': 'application/vnd.oasis.opendocument.presentation',
      '.html': 'text/html',
      '.htm': 'text/html',
      '.xml': 'application/xml',
      '.json': 'application/json',
      '.csv': 'text/csv',
      '.zip': 'application/zip',
      '.rar': 'application/x-rar-compressed',
      '.7z': 'application/x-7z-compressed',
      '.tar': 'application/x-tar',
      '.gz': 'application/gzip',
    };
    return mimeTypes[ext];
  }
  
  bool _isMediaFile(FileItem file) {
    final extension = file.extension.toLowerCase();

    // Image formats
    const imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.svg',
    ];
    if (imageExtensions.contains(extension)) return true;

    // Video formats
    const videoExtensions = [
      '.mp4',
      '.avi',
      '.mov',
      '.mkv',
      '.webm',
      '.flv',
      '.wmv',
      '.m4v',
    ];
    if (videoExtensions.contains(extension)) return true;

    // Audio formats
    const audioExtensions = [
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.ogg',
      '.m4a',
      '.wma',
      '.opus',
    ];
    if (audioExtensions.contains(extension)) return true;

    // Explicitly exclude documents to ensure they open with external apps
    const documentExtensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.rtf',
      '.odt',
      '.ods',
      '.odp',
      '.html',
      '.htm',
      '.xml',
      '.json',
      '.csv',
      '.zip',
      '.rar',
      '.7z',
      '.tar',
      '.gz',
    ];
    if (documentExtensions.contains(extension)) return false;

    return false;
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

  void _showDocumentOpenDialog(BuildContext context, FileItem file) {
    developer.log('[DIALOG] _showDocumentOpenDialog called for: ${file.name}', name: 'CategoryDetails');
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    developer.log('[DIALOG] About to show dialog...', name: 'CategoryDetails');
    
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
                CategoryUIMapper.getColor(widget.category.id).withValues(alpha: 0.05),
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
                      CategoryUIMapper.getColor(widget.category.id).withValues(alpha: 0.2),
                      CategoryUIMapper.getColor(widget.category.id).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getDocumentIcon(file.extension),
                  size: 40,
                  color: CategoryUIMapper.getColor(widget.category.id),
                ),
              ),
              const SizedBox(height: 20),
              
              // File name
              Text(
                file.name,
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
                    Text(
                      '${SizeFormatter.formatBytes(file.sizeInBytes)} • ${file.extension.toUpperCase().replaceFirst('.', '')}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                              Text('Opening ${file.name}...'),
                            ],
                          ),
                          backgroundColor: CategoryUIMapper.getColor(widget.category.id),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      
                      try {
                        bool opened = false;
                        
                        // Check if it's a content URI
                        if (ContentUriService.isContentUri(file.path)) {
                          developer.log('[Document Dialog] Opening content URI: ${file.path}', name: 'CategoryDetails');
                          // Get appropriate mime type
                          final mimeType = _getMimeTypeForDocument(file.extension);
                          opened = await ContentUriService.openContentUri(
                            file.path,
                            mimeType: mimeType,
                          );
                          developer.log('[Document Dialog] ContentUriService result: $opened', name: 'CategoryDetails');
                        } else {
                          developer.log('[Document Dialog] Opening regular file: ${file.path}', name: 'CategoryDetails');
                          // For regular files, use OpenFilex
                          final result = await OpenFilex.open(file.path);
                          opened = result.type == ResultType.done;
                          developer.log('[Document Dialog] OpenFilex result: ${result.type}', name: 'CategoryDetails');
                        }
                        
                        if (!opened && context.mounted) {
                          // If opening fails, try share as fallback
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Could not open file. Sharing instead...'),
                              backgroundColor: colorScheme.tertiary,
                            ),
                          );
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            subject: file.name,
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        }
                      } catch (e) {
                        developer.log('[Document Dialog] Error opening file: $e', name: 'CategoryDetails');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error opening file: ${e.toString()}'),
                              backgroundColor: colorScheme.error,
                              action: SnackBarAction(
                                label: 'Share',
                                textColor: Colors.white,
                                onPressed: () => _shareFile(file),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CategoryUIMapper.getColor(widget.category.id),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new),
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
  
  IconData _getDocumentIcon(String extension) {
    final ext = extension.toLowerCase();
    
    // Document types
    if (ext == '.pdf') return Icons.picture_as_pdf;
    if (ext == '.doc' || ext == '.docx') return Icons.description;
    if (ext == '.xls' || ext == '.xlsx') return Icons.table_chart;
    if (ext == '.ppt' || ext == '.pptx') return Icons.slideshow;
    if (ext == '.txt' || ext == '.rtf') return Icons.text_snippet;
    if (ext == '.html' || ext == '.htm') return Icons.web;
    if (ext == '.xml' || ext == '.json') return Icons.code;
    if (ext == '.csv') return Icons.table_rows;
    if (ext == '.zip' || ext == '.rar' || ext == '.7z' || ext == '.tar' || ext == '.gz') {
      return Icons.folder_zip;
    }
    
    // Default document icon
    return Icons.insert_drive_file;
  }
}

// Enhanced file list item with magical visuals
class _MagicalFileListItem extends StatefulWidget {
  final FileItem file;
  final Category category;
  final VoidCallback onTap;
  final int index;
  final bool isDark;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onLongPress;

  const _MagicalFileListItem({
    required this.file,
    required this.category,
    required this.onTap,
    required this.index,
    required this.isDark,
    required this.isSelected,
    required this.selectionMode,
    this.onLongPress,
  });

  @override
  State<_MagicalFileListItem> createState() => _MagicalFileListItemState();
}

class _MagicalFileListItemState extends State<_MagicalFileListItem> {
  bool _isPressed = false;

  IconData _getFileIcon() {
    final extension = widget.file.extension.toLowerCase();
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
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                CategoryUIMapper.getColor(widget.category.id).withValues(
                  alpha: widget.isDark ? .08 : .12,
                ),
                CategoryUIMapper.getColor(widget.category.id).withValues(
                  alpha: widget.isDark ? .04 : .08,
                ),
                colorScheme.surfaceContainer.withValues(alpha: .5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .1),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                developer.log('[ITEM] InkWell onTap triggered for: ${widget.file.name}', name: 'CategoryDetails');
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(20),
              splashColor: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .1),
              highlightColor: CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .05),
              child: Container(
                padding: const EdgeInsets.all(AppSize.paddingMedium),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        // Magical icon container
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .2),
                                CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: CategoryUIMapper.getColor(widget.category.id).withValues(
                                alpha: .3,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CategoryUIMapper.getColor(widget.category.id).withValues(
                                  alpha: .25,
                                ),
                                blurRadius: 12,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getFileIcon(),
                            color: CategoryUIMapper.getColor(widget.category.id),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSize.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.file.name,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: .5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${SizeFormatter.formatBytes(widget.file.sizeInBytes)} • ${_formatDate(widget.file.lastModified)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.selectionMode)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .15),
                                  CategoryUIMapper.getColor(widget.category.id).withValues(alpha: .05),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: CategoryUIMapper.getColor(widget.category.id),
                            ),
                          ),
                      ],
                    ),
                    // Selection checkbox overlay
                    if (widget.selectionMode)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.isSelected
                                  ? CategoryUIMapper.getColor(widget.category.id)
                                  : colorScheme.outline.withValues(alpha: .3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            widget.isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: widget.isSelected
                                ? CategoryUIMapper.getColor(widget.category.id)
                                : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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

// Custom background painter
class _CategoryBackgroundPainter extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  _CategoryBackgroundPainter({
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid pattern
    const spacing = 50.0;

    // Vertical lines
    paint.color = color;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines with gradient effect
    for (double y = 0; y < size.height; y += spacing) {
      paint.color = Color.lerp(color, secondaryColor, y / size.height)!;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw decorative circles at intersections
    final circlePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    for (double x = spacing; x < size.width; x += spacing * 2) {
      for (double y = spacing; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 3, circlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
