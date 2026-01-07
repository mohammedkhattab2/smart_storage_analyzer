import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/repositories/file_repository.dart';
import 'package:smart_storage_analyzer/domain/usecases/delete_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_files_usecase.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/optimized_file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/optimized_file_manager_view.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/optimized_file_manager_viewmodel.dart';

/// Optimized file manager screen with performance improvements
class OptimizedFileManagerScreen extends StatelessWidget {
  const OptimizedFileManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // Create optimized viewmodel
        final viewModel = OptimizedFileManagerViewModel(
          getFilesUsecase: sl<GetFilesUseCase>(),
          deleteFilesUsecase: sl<DeleteFilesUseCase>(),
          fileRepository: sl<FileRepository>(),
        );

        // Create cubit with viewmodel
        final cubit = OptimizedFileManagerCubit(viewModel);

        // Load initial files with pagination
        cubit.loadFiles(FileCategory.all);

        return cubit;
      },
      child: const OptimizedFileManagerView(),
    );
  }
}