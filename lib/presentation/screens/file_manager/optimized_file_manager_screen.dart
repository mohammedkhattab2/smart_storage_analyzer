import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/optimized_file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/optimized_file_manager_view.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Optimized file manager screen with performance improvements
///
/// This screen is responsible only for:
/// - Reading the initial category (if provided by the router)
/// - Triggering the first `loadFiles` call in the cubit
///
/// All heavy logic is still inside the cubit and data/domain layers.
class OptimizedFileManagerScreen extends StatefulWidget {
  /// Optional initial category for the first load (e.g. open directly on Large).
  final FileCategory? initialCategory;

  const OptimizedFileManagerScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<OptimizedFileManagerScreen> createState() => _OptimizedFileManagerScreenState();
}

class _OptimizedFileManagerScreenState extends State<OptimizedFileManagerScreen> {
  @override
  void initState() {
    super.initState();
    // Load files only if not already loaded
    final fileManagerCubit = context.read<OptimizedFileManagerCubit>();
    if (fileManagerCubit.state is FileManagerInitial) {
      final initialCategory = widget.initialCategory ?? FileCategory.all;
      Logger.info('[FileManagerScreen] Loading files - initial category: $initialCategory');
      fileManagerCubit.loadFiles(initialCategory);
    } else {
      Logger.debug('[FileManagerScreen] Skipping load - state is ${fileManagerCubit.state.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const OptimizedFileManagerView();
  }
}