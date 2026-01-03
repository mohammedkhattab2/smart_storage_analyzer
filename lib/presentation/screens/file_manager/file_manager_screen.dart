import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/value_objects/file_category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/file_manager/file_manager_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/file_manager/file_manager_view.dart';

class FileManagerScreen extends StatelessWidget {
  const FileManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FileManagerCubit>()..loadFiles(FileCategory.all),
      child: const FileManagerView(),
    );
  }
}
