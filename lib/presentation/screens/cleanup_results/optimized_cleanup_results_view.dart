import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/skeleton_loader.dart';
import 'package:smart_storage_analyzer/presentation/cubits/cleanup_results/cleanup_results_cubit.dart';
import 'package:go_router/go_router.dart';

/// Optimized cleanup results view with progressive loading
class OptimizedCleanupResultsView extends StatefulWidget {
  final StorageAnalysisResults results;

  const OptimizedCleanupResultsView({
    super.key,
    required this.results,
  });

  @override
  State<OptimizedCleanupResultsView> createState() => _OptimizedCleanupResultsViewState();
}

class _OptimizedCleanupResultsViewState extends State<OptimizedCleanupResultsView> 
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  
  // Progressive loading state
  bool _cacheLoaded = false;
  bool _tempLoaded = false;
  bool _duplicatesLoaded = false;
  bool _largeFilesLoaded = false;
  bool _oldFilesLoaded = false;
  
  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Start progressive loading
    _startProgressiveLoading();
  }
  
  void _startProgressiveLoading() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Load cache files
    setState(() => _cacheLoaded = true);
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Load temp files
    setState(() => _tempLoaded = true);
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Load duplicates
    setState(() => _duplicatesLoaded = true);
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Load large files
    setState(() => _largeFilesLoaded = true);
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Load old files
    setState(() => _oldFilesLoaded = true);
    
    // Animate progress
    _progressController.forward();
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Calculate total cleanable space progressively
    double totalCleanableSpace = 0;
    if (_cacheLoaded) totalCleanableSpace += widget.results.totalCacheSize.toDouble();
    if (_tempLoaded) totalCleanableSpace += widget.results.totalTempSize.toDouble();
    if (_duplicatesLoaded) totalCleanableSpace += widget.results.totalDuplicatesSize.toDouble();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, totalCleanableSpace),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSize.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card with animation
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeController.value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - _fadeController.value)),
                            child: _buildSummaryCard(context, totalCleanableSpace),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: AppSize.paddingLarge),
                    
                    // Cleanable items section
                    Text(
                      'Cleanable Items',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSize.paddingMedium),
                    
                    // Progressive item loading
                    _buildProgressiveItems(context),
                    
                    const SizedBox(height: AppSize.paddingLarge),
                    
                    // Scan summary section
                    if (_oldFilesLoaded) ...[
                      Text(
                        'Scan Summary',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSize.paddingMedium),
                      _buildScanSummary(context),
                    ],
                  ],
                ),
              ),
            ),
            
            // Bottom action bar
            _buildBottomActionBar(context, totalCleanableSpace),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double totalCleanableSpace) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha:  0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: AppSize.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Complete',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    key: ValueKey(totalCleanableSpace),
                    '${SizeFormatter.formatBytes(totalCleanableSpace.toInt())} can be cleaned',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalCleanableSpace) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha:  0.3),
            colorScheme.primaryContainer.withValues(alpha:  0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha:  0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                context,
                icon: Icons.folder_open,
                label: 'Total Files',
                value: widget.results.totalFilesScanned.toString(),
                color: colorScheme.primary,
              ),
              _buildStatItem(
                context,
                icon: Icons.storage,
                label: 'Total Size',
                value: SizeFormatter.formatBytes(widget.results.totalSpaceUsed),
                color: colorScheme.secondary,
              ),
              _buildStatItem(
                context,
                icon: Icons.cleaning_services,
                label: 'Cleanable',
                value: SizeFormatter.formatBytes(totalCleanableSpace.toInt()),
                color: colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSize.paddingLarge),
          
          // Animated progress bar
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final percentage = widget.results.totalSpaceUsed > 0
                  ? (totalCleanableSpace / widget.results.totalSpaceUsed)
                  : 0.0;
              
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Potential Space Recovery',
                        style: textTheme.bodyMedium,
                      ),
                      Text(
                        '${(percentage * 100 * _progressController.value).toStringAsFixed(1)}%',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSize.paddingSmall),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage * _progressController.value,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha:  0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressiveItems(BuildContext context) {
    return Column(
      children: [
        // Cache files
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _cacheLoaded
              ? _buildCleanableItem(
                  context,
                  icon: Icons.cached,
                  title: 'Cache Files',
                  count: widget.results.cacheFiles.length,
                  size: widget.results.totalCacheSize.toDouble(),
                  color: Colors.orange,
                )
              : const SkeletonLoader(height: 80),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        
        // Temp files
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _tempLoaded
              ? _buildCleanableItem(
                  context,
                  icon: Icons.folder_delete,
                  title: 'Temporary Files',
                  count: widget.results.temporaryFiles.length,
                  size: widget.results.totalTempSize.toDouble(),
                  color: Colors.red,
                )
              : const SkeletonLoader(height: 80),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        
        // Duplicate files
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _duplicatesLoaded
              ? _buildCleanableItem(
                  context,
                  icon: Icons.file_copy,
                  title: 'Duplicate Files',
                  count: widget.results.duplicateFiles.length,
                  size: widget.results.totalDuplicatesSize.toDouble(),
                  color: Colors.purple,
                )
              : const SkeletonLoader(height: 80),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        
        // Large files
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _largeFilesLoaded
              ? _buildInfoItem(
                  context,
                  icon: Icons.sd_storage,
                  title: 'Large Files',
                  count: widget.results.largeOldFiles.length,
                  size: widget.results.totalLargeOldSize.toDouble(),
                  color: Colors.blue,
                )
              : const SkeletonLoader(height: 80),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        
        // Old files
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _oldFilesLoaded
              ? _buildInfoItem(
                  context,
                  icon: Icons.history,
                  title: 'Large Old Files (>90 days)',
                  count: widget.results.largeOldFiles.length,
                  size: widget.results.totalLargeOldSize.toDouble(),
                  color: Colors.grey,
                )
              : const SkeletonLoader(height: 80),
        ),
      ],
    );
  }

  Widget _buildCleanableItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required double size,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues (alpha:  0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha:  0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha:  0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count files • ${SizeFormatter.formatBytes(size.toInt())}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha:  0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Cleanable',
              style: textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required double size,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha:  0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha:  0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSize.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count files • ${SizeFormatter.formatBytes(size.toInt())}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.info_outline,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildScanSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha:  0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppSize.paddingSmall),
              Text(
                'Analysis Details',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSize.paddingMedium),
          _buildSummaryRow(
            context,
            'Total files scanned:',
            widget.results.totalFilesScanned.toString(),
          ),
          _buildSummaryRow(
            context,
            'Total size analyzed:',
            SizeFormatter.formatBytes(widget.results.totalSpaceUsed),
          ),
          _buildSummaryRow(
            context,
            'Scan duration:',
            widget.results.analysisDuration.inSeconds > 0
                ? '${widget.results.analysisDuration.inSeconds}s'
                : '<1s',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, double totalCleanableSpace) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Later'),
              ),
            ),
            const SizedBox(width: AppSize.paddingMedium),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: totalCleanableSpace > 0
                    ? () {
                        HapticFeedback.mediumImpact();
                        _startCleanup(context);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cleaning_services, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Clean ${SizeFormatter.formatBytes(totalCleanableSpace.toInt())}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCleanup(BuildContext context) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Cleanup'),
        content: Text(
          'Are you sure you want to delete ${SizeFormatter.formatBytes(widget.results.totalCacheSize + widget.results.totalTempSize + widget.results.totalDuplicatesSize)} of files?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performCleanup(context);
            },
            child: const Text('Clean Now'),
          ),
        ],
      ),
    );
  }

  void _performCleanup(BuildContext context) {
    final cubit = context.read<CleanupResultsCubit>();
    
    // Select all cleanable categories (cache, temp, duplicates)
    cubit.selectAll();
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: BlocConsumer<CleanupResultsCubit, CleanupResultsState>(
          listener: (context, state) {
            if (state is CleanupCompleted) {
              Navigator.of(dialogContext).pop();
              _showCleanupSuccess(context, state);
            } else if (state is CleanupError) {
              Navigator.of(dialogContext).pop();
              _showCleanupError(context, state);
            }
          },
          builder: (context, state) {
            if (state is CleanupInProgress) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: state.progress),
                    const SizedBox(height: 16),
                    Text(state.message),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    
    // Perform cleanup
    cubit.performCleanup(context: context);
  }

  void _showCleanupSuccess(BuildContext context, CleanupCompleted state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Cleanup Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Successfully cleaned ${state.filesDeleted} files'),
            const SizedBox(height: 8),
            Text(
              'Space freed: ${SizeFormatter.formatBytes(state.spaceFreed)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/dashboard');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showCleanupError(BuildContext context, CleanupError state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}