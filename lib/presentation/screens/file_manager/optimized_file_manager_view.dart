import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/optimized_file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/file_tabs_widget.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/core/services/saf_file_manager_service.dart';
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
  
  // SAF file manager service
  final SafFileManagerService _safService = SafFileManagerService();
  bool _isScanningSaf = false;
  List<ScannedFileItem>? _safFiles;
  FileCategory _currentSafCategory = FileCategory.all;

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
      // Remove automatic pop - let natural navigation work
      // Any dialog will dismiss itself
      _showErrorSnackBar(context, state.message);
    } else if (state is FileManagerLoaded) {
      // Remove automatic pop - let natural navigation work
      // Dialog dismissal should be handled by the dialog itself
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
      child: Column(
        children: [
          Row(
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
                    if (_safService.hasFolderSelected)
                      Text(
                        _safService.selectedFolderName ?? 'Selected Folder',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      )
                    else if (state is FileManagerLoaded)
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
              // Select Folder Button
              IconButton(
                icon: Icon(
                  _safService.hasFolderSelected ? Icons.folder_open : Icons.create_new_folder,
                  color: colorScheme.primary,
                ),
                onPressed: _selectFolder,
                tooltip: 'Select Folder',
              ),
            ],
          ),
          // Show folder info if selected
          if (_safService.hasFolderSelected && _safFiles != null) ...[
            const SizedBox(height: AppSize.paddingSmall),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.paddingMedium,
                vertical: AppSize.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSize.paddingSmall),
                  Expanded(
                    child: Text(
                      '${_safFiles!.length} files from ${_safService.selectedFolderName}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFolderSelection,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _selectFolder() async {
    HapticFeedback.mediumImpact();
    
    final result = await _safService.selectFolder();
    if (result != null) {
      setState(() {
        _isScanningSaf = true;
      });
      
      final scanResult = await _safService.scanFolder();
      
      setState(() {
        _isScanningSaf = false;
        _safFiles = scanResult.files;
        _currentSafCategory = FileCategory.all;
      });
    }
  }
  
  void _clearFolderSelection() {
    HapticFeedback.lightImpact();
    _safService.clearFolderSelection();
    setState(() {
      _safFiles = null;
      _currentSafCategory = FileCategory.all;
    });
  }

  Widget _buildTabs(BuildContext context, OptimizedFileManagerState state) {
    final currentCategory = _safService.hasFolderSelected
        ? _currentSafCategory
        : (state is FileManagerLoaded ? state.currentCategory : FileCategory.all);

    return FileTabsWidget(
      currentCategory: currentCategory,
      onTabChanged: (category) {
        HapticFeedback.selectionClick();
        if (_safService.hasFolderSelected) {
          setState(() {
            _currentSafCategory = category;
          });
        } else {
          context.read<OptimizedFileManagerCubit>().changeCategory(category);
        }
      },
    );
  }

  Widget _buildContent(BuildContext context, OptimizedFileManagerState state) {
    // Show scanning state
    if (_isScanningSaf) {
      return _buildSafScanningState(context);
    }
    
    // If SAF folder is selected, show SAF files
    if (_safService.hasFolderSelected && _safFiles != null) {
      return _buildSafContent(context);
    }
    
    // Show prompt to select folder if no data
    if (state is FileManagerInitial || (state is FileManagerLoaded && state.files.isEmpty && !_safService.hasFolderSelected)) {
      return _buildSelectFolderPrompt(context);
    }
    
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
  
  Widget _buildSelectFolderPrompt(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.2),
                    colorScheme.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge),
            Text(
              'Select a Folder to Manage',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppSize.paddingLarge),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Choose a folder to scan and manage your files. '
                'You can view all files, find large files, duplicates, and old files.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSize.paddingXLarge * 1.5),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
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
                  onTap: _selectFolder,
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildSafScanningState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                Icon(
                  Icons.folder_rounded,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          Text(
            'Scanning Folder...',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSize.paddingSmall),
          Text(
            'This may take a moment',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSafContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final files = _safService.getFilesByCategory(_currentSafCategory);
    
    if (files.isEmpty) {
      return _buildEmptyState(context, _currentSafCategory);
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isScanningSaf = true;
        });
        final result = await _safService.scanFolder();
        setState(() {
          _isScanningSaf = false;
          _safFiles = result.files;
        });
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSize.paddingMedium),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return _SafFileItemWidget(
            file: file,
            colorScheme: colorScheme,
          );
        },
      ),
    );
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
/// SAF File Item Widget for displaying files from SAF scan
class _SafFileItemWidget extends StatelessWidget {
  final ScannedFileItem file;
  final ColorScheme colorScheme;

  const _SafFileItemWidget({
    required this.file,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSize.paddingSmall),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            // Open file using open_filex
            try {
              final result = await OpenFilex.open(file.uri);
              if (result.type != ResultType.done && context.mounted) {
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
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppSize.paddingMedium),
            child: Row(
              children: [
                // File icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(),
                    color: _getFileColor(),
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
                        style: textTheme.bodyLarge?.copyWith(
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
                            SizeFormatter.formatBytes(file.size),
                            style: textTheme.bodySmall?.copyWith(
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
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Icons.image;
    } else if (['.mp4', '.avi', '.mkv', '.mov', '.webm'].contains(ext)) {
      return Icons.video_file;
    } else if (['.mp3', '.wav', '.flac', '.aac', '.ogg'].contains(ext)) {
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

  Color _getFileColor() {
    final ext = file.extension.toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      return colorScheme.tertiary;
    } else if (['.mp4', '.avi', '.mkv', '.mov'].contains(ext)) {
      return colorScheme.error;
    } else if (['.mp3', '.wav', '.flac'].contains(ext)) {
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