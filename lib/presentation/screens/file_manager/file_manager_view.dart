import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/file_manager_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/file_tabs_widget.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/core/services/file_operations_service.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/skeleton_loader.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha: 0.02),
              colorScheme.secondary.withValues(alpha: 0.02),
              colorScheme.tertiary.withValues(alpha: 0.01),
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Magical background
            _buildMagicalBackground(context),
            
            SafeArea(
              child: BlocConsumer<FileManagerCubit, FileManagerState>(
                listener: (context, state) {
                  if (state is FileManagerDeleting) {
                    _showMagicalDeletingDialog(context);
                  } else if (state is FileManagerError) {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                    _showMagicalErrorSnackBar(context, state.message);
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
                      _buildMagicalHeader(
                        context,
                        showSelectionActions: state is FileManagerLoaded && state.selectedCount > 0,
                      ),
                      if (state is! FileManagerLoading)
                        _buildMagicalTabs(
                          context,
                          currentCategory: state is FileManagerLoaded
                              ? state.currentCategory
                              : FileCategory.all,
                        ),
                      Expanded(child: _buildContent(context, state)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMagicalBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // Top left orb
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.06),
                  colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom right orb
        Positioned(
          bottom: -120,
          right: -100,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.secondary.withValues(alpha: 0.05),
                  colorScheme.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Center accent
        Positioned(
          top: size.height * 0.5,
          left: size.width * 0.8,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.tertiary.withValues(alpha: 0.04),
                  colorScheme.tertiary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Pattern overlay
        CustomPaint(
          size: size,
          painter: _FileManagerBackgroundPainter(
            primaryColor: colorScheme.primary.withValues(alpha: 0.02),
            secondaryColor: colorScheme.secondary.withValues(alpha: 0.01),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalHeader(BuildContext context, {required bool showSelectionActions}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface.withValues(alpha: 0.9),
            colorScheme.surface.withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.folder_rounded,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'File Manager',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'Manage your device files',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (showSelectionActions) ...[
            _buildMagicalActionButton(
              context,
              icon: Icons.select_all,
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<FileManagerCubit>().toggleSelectAll();
              },
            ),
            const SizedBox(width: AppSize.paddingSmall),
            _buildMagicalActionButton(
              context,
              icon: Icons.clear,
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<FileManagerCubit>().clearSelection();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMagicalActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.8),
            colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalTabs(BuildContext context, {required FileCategory currentCategory}) {
    return FileTabsWidget(
      currentCategory: currentCategory,
      onTabChanged: (category) {
        HapticFeedback.selectionClick();
        context.read<FileManagerCubit>().changeCategory(category);
      },
    );
  }

  void _showMagicalDeletingDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSize.paddingXLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              Text(
                "Deleting files...",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSize.paddingSmall),
              Text(
                "Please wait while we remove the selected files",
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMagicalErrorSnackBar(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSize.paddingSmall),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: colorScheme.onError,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSize.paddingMedium),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(AppSize.paddingMedium),
        elevation: 6,
      ),
    );
  }

  Widget _buildContent(BuildContext context, FileManagerState state) {
    if (state is FileManagerLoading) {
      return _buildMagicalLoadingWidget(context);
    }

    if (state is FileManagerLoaded) {
      if (state.files.isEmpty) {
        return _buildMagicalEmptyState(context, state.currentCategory);
      }

      return Stack(
        children: [
          ListView.builder(
            key: ValueKey(state.currentCategory),
            padding: EdgeInsets.only(
              left: AppSize.paddingMedium,
              right: AppSize.paddingMedium,
              top: AppSize.paddingMedium,
              bottom: _isSelectionMode ? 80 : AppSize.paddingMedium,
            ),
            itemCount: state.files.length,
            itemBuilder: (context, index) {
              final file = state.files[index];
              final isSelected = state.selectedFileIds.contains(file.id);

              return _MagicalFileItemWidget(
                file: file,
                isSelected: isSelected,
                isSelectionMode: _isSelectionMode,
                index: index,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (_isSelectionMode) {
                    context.read<FileManagerCubit>().toggleFileSelection(file.id);
                  } else {
                    // Open file
                    final fileOperations = FileOperationsService();
                    final success = await fileOperations.openFile(file.path);
                    
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cannot open ${file.name}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSize.radiusSmall,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  }
                  context.read<FileManagerCubit>().toggleFileSelection(file.id);
                },
              );
            },
          ),
          if (_isSelectionMode && state.selectedCount > 0)
            _buildSelectionBottomBar(context, state),
        ],
      );
    }

    if (state is FileManagerError) {
      return _buildMagicalErrorState(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildSelectionBottomBar(BuildContext context, FileManagerLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSize.paddingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface.withValues(alpha: 0.95),
              colorScheme.surface,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
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
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      SizeFormatter.formatBytes(
                        state.files
                            .where((f) => state.selectedFileIds.contains(f.id))
                            .fold(0, (sum, file) => sum + file.sizeInBytes),
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomAction(
                context,
                icon: Icons.share_rounded,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final selectedFiles = state.files
                      .where((f) => state.selectedFileIds.contains(f.id))
                      .toList();
                  
                  if (selectedFiles.isEmpty) return;
                  
                  final fileOperations = FileOperationsService();
                  final success = await fileOperations.shareFiles(
                    selectedFiles.map((f) => f.path).toList(),
                  );
                  
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Failed to share files'),
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
              ),
              const SizedBox(width: AppSize.paddingSmall),
              _buildBottomAction(
                context,
                icon: Icons.delete_rounded,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showDeleteConfirmationDialog(context, state);
                },
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, FileManagerLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedCount = state.selectedCount;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.error.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.error.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSize.paddingXLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.error.withValues(alpha: 0.1),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  size: 40,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              Text(
                'Delete $selectedCount ${selectedCount == 1 ? 'File' : 'Files'}?',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSize.paddingSmall),
              Text(
                'This action cannot be undone. Are you sure you want to permanently delete the selected files?',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSize.paddingXLarge),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingMedium),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<FileManagerCubit>().deleteSelectedFiles();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalLoadingWidget(BuildContext context) {
    return const SkeletonListLoader(
      itemCount: 8,
      itemHeight: 80,
      padding: EdgeInsets.all(AppSize.paddingMedium),
    );
  }

  Widget _buildMagicalEmptyState(BuildContext context, FileCategory category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
            width: 140,
            height: 140,
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
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 72,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            message,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSize.paddingLarge,
              vertical: AppSize.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Try selecting a different category',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalErrorState(BuildContext context, FileManagerError state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.errorContainer.withValues(alpha: 0.3),
                    colorScheme.errorContainer.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.error.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  colorScheme.error,
                  colorScheme.error.withValues(alpha: 0.8),
                ],
              ).createShader(bounds),
              child: Text(
                'Error loading files',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppSize.paddingMedium),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                state.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.error,
                    colorScheme.error.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.error.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.read<FileManagerCubit>().loadFiles(FileCategory.all);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingXLarge,
                      vertical: AppSize.paddingMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppSize.paddingSmall),
                        const Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
}

class _MagicalFileItemWidget extends StatefulWidget {
  final dynamic file;
  final bool isSelected;
  final bool isSelectionMode;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MagicalFileItemWidget({
    required this.file,
    required this.isSelected,
    required this.isSelectionMode,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_MagicalFileItemWidget> createState() => _MagicalFileItemWidgetState();
}

class _MagicalFileItemWidgetState extends State<_MagicalFileItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Different gradient patterns for variety
    final gradientColors = [
      [colorScheme.primary, colorScheme.secondary],
      [colorScheme.secondary, colorScheme.tertiary],
      [colorScheme.tertiary, colorScheme.primary],
      [colorScheme.primary, colorScheme.tertiary],
    ];
    
    final colors = gradientColors[widget.index % gradientColors.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSize.paddingSmall),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (_isHovered || widget.isSelected)
                  ? colors[0].withValues(alpha: 0.05)
                  : colorScheme.surfaceContainer.withValues(alpha: 0.3),
              (_isHovered || widget.isSelected)
                  ? colors[1].withValues(alpha: 0.03)
                  : colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? colors[0].withValues(alpha: 0.4)
                : (_isHovered
                    ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                    : Colors.transparent),
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (_isHovered || widget.isSelected)
              BoxShadow(
                color: (widget.isSelected ? colors[0] : colorScheme.shadow)
                    .withValues(alpha: 0.15),
                blurRadius: _isHovered ? 16 : 12,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(AppSize.paddingMedium),
              child: Row(
                children: [
                  // File icon with magical styling
                  Transform.scale(
                    scale: widget.isSelected ? 1.1 : 1.0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _getFileColor(widget.file.extension, colorScheme)
                                .withValues(alpha: 0.2),
                            _getFileColor(widget.file.extension, colorScheme)
                                .withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _getFileColor(widget.file.extension, colorScheme)
                              .withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getFileColor(widget.file.extension, colorScheme)
                                .withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getFileIcon(widget.file.extension),
                        color: _getFileColor(widget.file.extension, colorScheme),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingMedium),
                  // File info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.file.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.isSelected
                                ? colors[0]
                                : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildInfoChip(
                              context,
                              icon: Icons.storage_rounded,
                              text: SizeFormatter.formatBytes(widget.file.sizeInBytes),
                              color: colors[0],
                            ),
                            const SizedBox(width: AppSize.paddingSmall),
                            _buildInfoChip(
                              context,
                              icon: Icons.access_time_rounded,
                              text: _getTimeAgo(widget.file.lastModified),
                              color: colors[1],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Selection indicator
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: widget.isSelected
                          ? LinearGradient(
                              colors: [
                                colors[0],
                                colors[1],
                              ],
                            )
                          : null,
                      border: widget.isSelected
                          ? null
                          : Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: 2,
                            ),
                      shape: BoxShape.circle,
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: colors[0].withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: widget.isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: colorScheme.onPrimary,
                            size: 20,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSize.paddingSmall,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico',
    ].contains(ext)) {
      return Icons.image_rounded;
    }
    // Videos
    else if ([
      '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm',
    ].contains(ext)) {
      return Icons.video_file_rounded;
    }
    // Audio
    else if ([
      '.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a',
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
      '.xml', '.json', '.html', '.css', '.js', '.dart', '.java', '.kt',
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
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico',
    ].contains(ext)) {
      return colorScheme.tertiary;
    } else if ([
      '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm',
    ].contains(ext)) {
      return colorScheme.error;
    } else if ([
      '.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a',
    ].contains(ext)) {
      return colorScheme.secondary;
    } else if ([
      '.pdf', '.doc', '.docx', '.txt', '.odt', '.xls', '.xlsx', '.csv', '.ppt', '.pptx',
    ].contains(ext)) {
      return colorScheme.primary;
    } else if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(ext)) {
      return Color.alphaBlend(
        colorScheme.tertiary.withValues(alpha: 0.5),
        colorScheme.surface,
      );
    } else if (['.apk', '.xapk', '.aab'].contains(ext)) {
      return Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.7),
        colorScheme.surface,
      );
    } else {
      return colorScheme.primary;
    }
  }
}

// Custom painter for background pattern
class _FileManagerBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  
  _FileManagerBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw subtle dots pattern
    paint.color = primaryColor;
    for (double x = 0; x < size.width; x += 50) {
      for (double y = 0; y < size.height; y += 50) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
    
    // Draw diagonal lines
    paint.color = secondaryColor;
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;
    
    for (double i = -size.height; i < size.width; i += 100) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
