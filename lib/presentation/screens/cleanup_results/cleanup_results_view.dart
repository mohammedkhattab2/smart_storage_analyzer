import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/domain/entities/file_item.dart';
import 'package:smart_storage_analyzer/presentation/cubits/cleanup_results/cleanup_results_cubit.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/repositories/storage_repository.dart';
import 'package:smart_storage_analyzer/data/repositories/storage_repository_impl.dart';
import 'package:smart_storage_analyzer/presentation/cubits/storage_analysis/storage_analysis_cubit.dart';

class CleanupResultsView extends StatelessWidget {
  const CleanupResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha: 0.02),
              colorScheme.secondary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildMagicalAppBar(context),

              // Main Content
              Expanded(
                child: BlocConsumer<CleanupResultsCubit, CleanupResultsState>(
                  listener: (context, state) {
                    if (state is CleanupCompleted) {
                      // Show dialog and navigate back after it's dismissed
                      _showMagicalCleanupCompletedDialog(context, state).then((
                        _,
                      ) {
                        if (context.mounted) {
                          // Reset storage analysis state to prevent loading screen
                          try {
                            final storageAnalysisCubit = sl<StorageAnalysisCubit>();
                            storageAnalysisCubit.resetState();
                          } catch (e) {
                            // Ignore errors - resetting state is not critical
                          }
                          
                          // Go directly to dashboard since we replaced the storage analysis route
                          context.go('/dashboard');
                          
                          // Clear category cache in storage repository to force fresh data
                          try {
                            final storageRepo = sl<StorageRepository>() as StorageRepositoryImpl;
                            storageRepo.clearCategoriesCache();
                          } catch (e) {
                            // Ignore errors - cache clearing is not critical
                          }
                        }
                      });
                    } else if (state is CleanupError) {
                      _showMagicalErrorSnackBar(context, state.message);
                    }
                  },
                  builder: (context, state) {
                    if (state is CleanupResultsLoaded) {
                      return _buildMagicalLoadedView(context, state);
                    } else if (state is CleanupInProgress) {
                      return _buildMagicalProgressView(context, state);
                    } else if (state is CleanupCompleted) {
                      // Don't show loader for completed state
                      return const SizedBox.shrink();
                    }
                    return Center(child: _buildMagicalLoader(context));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Reset storage analysis state to prevent loading screen
                try {
                  final storageAnalysisCubit = sl<StorageAnalysisCubit>();
                  storageAnalysisCubit.resetState();
                } catch (e) {
                  // Ignore errors - resetting state is not critical
                }
                
                // Clear category cache before going back to dashboard
                try {
                  // Access the storage repository to clear cache
                  final storageRepo = sl<StorageRepository>() as StorageRepositoryImpl;
                  storageRepo.clearCategoriesCache();
                } catch (e) {
                  // Ignore errors - cache clearing is not critical
                }
                
                // Go directly to dashboard since we replaced the storage analysis route
                context.go('/dashboard');
              },
            ),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ).createShader(bounds),
              child: Text(
                'Cleanup Results',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalLoadedView(
    BuildContext context,
    CleanupResultsLoaded state,
  ) {
    return Stack(
      children: [
        // Background decoration
        _buildMagicalBackground(context),

        Column(
          children: [
            // Summary Card
            _buildMagicalSummaryCard(context, state),

            // Action Buttons
            _buildMagicalActionButtons(context),

            const SizedBox(height: AppSize.paddingMedium),

            // Categories List with performance optimization
            // Filter to only show cache, temp files, and thumbnails
            Expanded(
              child: Builder(
                builder: (context) {
                  // Filter categories to only include cache, temp, and thumbnails
                  final filteredCategories = state.results.cleanupCategories
                      .where((category) {
                        // Only show cache, temp_files, and thumbnails categories
                        return category.icon == 'cache' ||
                               category.icon == 'temp_files' ||
                               category.icon == 'thumbnails';
                      })
                      .toList();
                  
                  if (filteredCategories.isEmpty) {
                    // Show a message if no categories to display
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: AppSize.paddingMedium),
                          Text(
                            'No cache, temporary files, or thumbnails found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSize.paddingSmall),
                          Text(
                            'Your device is already optimized!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingMedium,
                    ),
                    // Performance optimization: add caching and physics
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      final isSelected = state.selectedCategories.contains(
                        category.name,
                      );
                      final selectedFiles =
                          state.selectedFiles[category.name] ?? {};

                      // Wrap in RepaintBoundary for better performance
                      return RepaintBoundary(
                        child: _buildMagicalCategoryCard(
                          context,
                          category,
                          isSelected,
                          selectedFiles,
                          state,
                          index,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Action Bar
            _buildMagicalBottomBar(context, state),
          ],
        ),
      ],
    );
  }

  Widget _buildMagicalBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: CustomPaint(
        painter: _CleanupBackgroundPainter(
          primaryColor: colorScheme.primary.withValues(alpha: 0.03),
          secondaryColor: colorScheme.secondary.withValues(alpha: 0.02),
        ),
      ),
    );
  }

  Widget _buildMagicalSummaryCard(
    BuildContext context,
    CleanupResultsLoaded state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(AppSize.paddingMedium),
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.secondary.withValues(alpha: 0.06),
            colorScheme.tertiary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.cleaning_services_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSize.paddingMedium),
          Text(
            'Total Cleanup Potential',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSize.paddingSmall),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
            ).createShader(bounds),
            child: Text(
              SizeFormatter.formatBytes(state.results.totalCleanupPotential),
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSize.paddingSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSize.paddingMedium,
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
                  Icons.folder_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSize.paddingSmall),
                Text(
                  '${state.results.totalFilesScanned} files scanned',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.read<CleanupResultsCubit>().selectAll(),
                  borderRadius: BorderRadius.circular(11),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingMedium,
                      vertical: AppSize.paddingSmall + 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.select_all,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSize.paddingSmall),
                        Text(
                          'Select All',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSize.paddingSmall),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.secondary.withValues(alpha: 0.1),
                    colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      context.read<CleanupResultsCubit>().deselectAll(),
                  borderRadius: BorderRadius.circular(11),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingMedium,
                      vertical: AppSize.paddingSmall + 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.deselect,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSize.paddingSmall),
                        Text(
                          'Deselect All',
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalCategoryCard(
    BuildContext context,
    CleanupCategory category,
    bool isSelected,
    Set<String> selectedFiles,
    CleanupResultsLoaded state,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Different gradient colors for each category
    final gradientColors = [
      [colorScheme.primary, colorScheme.secondary],
      [colorScheme.secondary, colorScheme.tertiary],
      [colorScheme.tertiary, colorScheme.primary],
      [colorScheme.error, colorScheme.secondary],
      [colorScheme.primary, colorScheme.tertiary],
    ];

    final colors = gradientColors[index % gradientColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSize.paddingSmall),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[0].withValues(alpha: isSelected ? 0.08 : 0.03),
            colors[1].withValues(alpha: isSelected ? 0.06 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colors[0].withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colors[0].withValues(alpha: 0.2),
                  colors[0].withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getCategoryIcon(category.icon),
              color: isSelected ? colors[0] : colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSize.paddingSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors[0].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${category.files.length} files',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors[0],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSize.paddingSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSize.paddingSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors[1].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            SizeFormatter.formatBytes(category.totalSize),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors[1],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors[0].withValues(alpha: 0.1),
                      colors[1].withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    context.read<CleanupResultsCubit>().toggleCategorySelection(
                      category.name,
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSize.paddingSmall),
            child: Text(
              category.description,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
          children: [
            // Show only first 10 files initially for better performance
            ...category.files.take(10).map((file) {
              final isFileSelected = selectedFiles.contains(file.id);
              return _buildFileItem(
                context,
                file,
                isFileSelected,
                category.name,
                colorScheme,
                textTheme,
              );
            }),
            
            // Show "Load more" button if there are more files
            if (category.files.length > 10) ...[
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.5),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    // Show all files dialog
                    _showAllFilesDialog(
                      context,
                      category,
                      selectedFiles,
                    );
                  },
                  icon: Icon(
                    Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'View all ${category.files.length} files',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMagicalBottomBar(
    BuildContext context,
    CleanupResultsLoaded state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selected info with magical styling
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSize.paddingMedium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.05),
                      colorScheme.secondary.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSize.paddingSmall),
                        Text(
                          '${state.selectedFilesCount} files selected',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ).createShader(bounds),
                      child: Text(
                        SizeFormatter.formatBytes(state.totalSelectedSize),
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSize.paddingMedium),
            // Clean button with magical gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: state.selectedFilesCount > 0
                      ? [colorScheme.primary, colorScheme.secondary]
                      : [
                          colorScheme.onSurface.withValues(alpha: 0.12),
                          colorScheme.onSurface.withValues(alpha: 0.12),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: state.selectedFilesCount > 0
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: state.selectedFilesCount > 0
                      ? () => _confirmMagicalCleanup(context)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingLarge,
                      vertical: AppSize.paddingMedium,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep,
                          color: state.selectedFilesCount > 0
                              ? Colors.white
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        const SizedBox(width: AppSize.paddingSmall),
                        Text(
                          'Clean Now',
                          style: TextStyle(
                            color: state.selectedFilesCount > 0
                                ? Colors.white
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                            fontWeight: FontWeight.w700,
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

  Widget _buildMagicalProgressView(
    BuildContext context,
    CleanupInProgress state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Magical circular progress
          Container(
            width: 200,
            height: 200,
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
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: state.progress,
                    strokeWidth: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.0),
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.secondary.withValues(alpha: 0.2),
                        colorScheme.primary.withValues(alpha: 0.0),
                      ],
                      transform: GradientRotation(state.progress * 2 * 3.14159),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cleaning_services,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: AppSize.paddingSmall),
                    Text(
                      '${(state.progress * 100).toInt()}%',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSize.paddingLarge,
              vertical: AppSize.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              state.message,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalLoader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: CircularProgressIndicator(
        strokeWidth: 4,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    FileItem file,
    bool isFileSelected,
    String categoryName,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(
          left: AppSize.paddingLarge * 2.5,
          right: AppSize.paddingMedium,
        ),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(file.extension),
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          file.name,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          SizeFormatter.formatBytes(file.sizeInBytes),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Checkbox(
          value: isFileSelected,
          onChanged: (_) {
            context.read<CleanupResultsCubit>().toggleFileSelection(
              categoryName,
              file.id,
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  void _showAllFilesDialog(
    BuildContext context,
    CleanupCategory category,
    Set<String> selectedFiles,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSize.paddingMedium),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category.icon),
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSize.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${category.files.length} files',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              
              // File list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSize.paddingSmall,
                  ),
                  itemCount: category.files.length,
                  itemBuilder: (context, index) {
                    final file = category.files[index];
                    final isFileSelected = selectedFiles.contains(file.id);
                    
                    return _buildFileItem(
                      context,
                      file,
                      isFileSelected,
                      category.name,
                      colorScheme,
                      textTheme,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmMagicalCleanup(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.error.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSize.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.error.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              Text(
                'Confirm Cleanup',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSize.paddingMedium),
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
                  'Are you sure you want to delete the selected files?\nThis action cannot be undone.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSize.paddingMedium,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingMedium),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.error,
                            colorScheme.error.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.error.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            context.read<CleanupResultsCubit>().performCleanup(
                              context: context,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSize.paddingMedium,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSize.paddingSmall),
                                const Text(
                                  'Delete Files',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Future<void> _showMagicalCleanupCompletedDialog(
    BuildContext context,
    CleanupCompleted state,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.secondary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: colorScheme.secondary.withValues(alpha: 0.15),
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
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.2),
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 56,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ).createShader(bounds),
                child: Text(
                  'Cleanup Completed!',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              Container(
                padding: const EdgeInsets.all(AppSize.paddingLarge),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.file_download_done,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSize.paddingSmall),
                        Text(
                          '${state.filesDeleted} files deleted',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.paddingSmall),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ).createShader(bounds),
                      child: Text(
                        '${SizeFormatter.formatBytes(state.spaceFreed)} freed',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSize.paddingXLarge),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSize.paddingMedium + 4,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(AppSize.paddingMedium),
        elevation: 6,
      ),
    );
  }

  IconData _getCategoryIcon(String icon) {
    switch (icon) {
      case 'cache':
        return Icons.cached;
      case 'temp_files':
        return Icons.folder_special;
      case 'duplicates':
        return Icons.content_copy;
      case 'old_files':
        return Icons.access_time;
      case 'thumbnails':
        return Icons.photo_size_select_small;
      default:
        return Icons.folder;
    }
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();
    if (['.jpg', '.png', '.gif', '.webp'].contains(ext)) {
      return Icons.image;
    } else if (['.mp4', '.avi', '.mkv', '.mov'].contains(ext)) {
      return Icons.video_file;
    } else if (['.mp3', '.wav', '.flac'].contains(ext)) {
      return Icons.audio_file;
    } else if (['.pdf', '.doc', '.txt'].contains(ext)) {
      return Icons.description;
    } else if (ext == '.tmp') {
      return Icons.file_present;
    }
    return Icons.insert_drive_file;
  }
}

// Custom painter for magical background
class _CleanupBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _CleanupBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating orbs
    paint.color = primaryColor;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.1), 80, paint);

    paint.color = secondaryColor;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.4), 120, paint);

    // Draw subtle lines
    paint.color = primaryColor.withValues(alpha: 0.5);
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2,
      size.width,
      size.height * 0.4,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
