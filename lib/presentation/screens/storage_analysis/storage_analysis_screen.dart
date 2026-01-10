import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/presentation/cubits/storage_analysis/storage_analysis_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/storage_analysis/storage_analysis_view.dart';

class StorageAnalysisScreen extends StatefulWidget {
  const StorageAnalysisScreen({super.key});

  @override
  State<StorageAnalysisScreen> createState() => _StorageAnalysisScreenState();
}

class _StorageAnalysisScreenState extends State<StorageAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // Use the global singleton and start analysis
    // Only force rerun if user explicitly requested it (e.g., from analyze button)
    // Otherwise, use cached results if available (1-hour cache)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StorageAnalysisCubit>().startAnalysis(forceRerun: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Remove PopScope completely - let natural navigation work
    // Cancellation is handled by the cancel button in the UI
    return BlocListener<StorageAnalysisCubit, StorageAnalysisState>(
        listener: (context, state) {
        if (state is StorageAnalysisCompleted) {
          // Add a subtle delay for smoother transition
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              // Replace storage analysis with cleanup results to avoid double back navigation
              context.pushReplacement('/cleanup-results', extra: state.results);
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
    );
  }
}
