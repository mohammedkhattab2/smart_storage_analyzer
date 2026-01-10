import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/optimized_file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/optimized_file_manager_view.dart';
import 'package:smart_storage_analyzer/core/utils/logger.dart';

/// Optimized file manager screen with performance improvements
class OptimizedFileManagerScreen extends StatefulWidget {
  const OptimizedFileManagerScreen({super.key});

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
      Logger.info('[FileManagerScreen] Loading files - state is initial');
      fileManagerCubit.loadFiles(FileCategory.all);
    } else {
      Logger.debug('[FileManagerScreen] Skipping load - state is ${fileManagerCubit.state.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const OptimizedFileManagerView();
  }
}