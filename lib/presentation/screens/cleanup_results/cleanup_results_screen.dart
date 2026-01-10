import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/presentation/cubits/cleanup_results/cleanup_results_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/cleanup_results/cleanup_results_view.dart';

class CleanupResultsScreen extends StatelessWidget {
  final StorageAnalysisResults results;

  const CleanupResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = sl<CleanupResultsCubit>();
        // Initialize in a post frame callback to ensure the widget is mounted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            cubit.initialize(results);
          }
        });
        return cubit;
      },
      child: const CleanupResultsView(),
    );
  }
}
