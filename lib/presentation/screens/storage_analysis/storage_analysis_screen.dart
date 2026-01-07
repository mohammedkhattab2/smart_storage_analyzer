import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/presentation/cubits/storage_analysis/storage_analysis_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/storage_analysis/storage_analysis_view.dart';

class StorageAnalysisScreen extends StatelessWidget {
  const StorageAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<StorageAnalysisCubit>()..startAnalysis(),
      child: BlocListener<StorageAnalysisCubit, StorageAnalysisState>(
        listener: (context, state) {
          if (state is StorageAnalysisCompleted) {
            // Add a subtle delay for smoother transition
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                // Navigate to cleanup results with a fade transition
                context.push('/cleanup-results', extra: state.results);
              }
            });
          } else if (state is StorageAnalysisError) {
            // Show error with a beautiful snackbar
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              context.pop();
            }
          } else if (state is StorageAnalysisCancelled) {
            // Smooth transition back to dashboard
            if (context.mounted) {
              context.pop();
            }
          }
        },
        child: const StorageAnalysisView(),
      ),
    );
  }
}
