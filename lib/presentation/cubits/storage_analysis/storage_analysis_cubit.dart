import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/storage_analysis_results.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/storage_analysis_viewmodel.dart';

part 'storage_analysis_state.dart';

class StorageAnalysisCubit extends Cubit<StorageAnalysisState> {
  final StorageAnalysisViewModel _viewModel;

  StorageAnalysisCubit({required StorageAnalysisViewModel viewModel})
      : _viewModel = viewModel,
        super(StorageAnalysisInitial());

  Future<void> startAnalysis() async {
    emit(StorageAnalysisInProgress(
      message: 'Preparing to scan storage...',
      progress: 0.0,
    ));

    try {
      // Simulated progress steps for analysis
      await _updateProgress('Scanning system files...', 0.1);
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _updateProgress('Analyzing images...', 0.2);
      await Future.delayed(const Duration(milliseconds: 800));
      
      await _updateProgress('Analyzing videos...', 0.35);
      await Future.delayed(const Duration(milliseconds: 800));
      
      await _updateProgress('Analyzing audio files...', 0.5);
      await Future.delayed(const Duration(milliseconds: 600));
      
      await _updateProgress('Analyzing documents...', 0.65);
      await Future.delayed(const Duration(milliseconds: 600));
      
      await _updateProgress('Analyzing applications...', 0.8);
      await Future.delayed(const Duration(milliseconds: 700));
      
      await _updateProgress('Finding duplicate files...', 0.9);
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _updateProgress('Calculating cleanup potential...', 0.95);
      
      // Perform actual analysis
      final results = await _viewModel.performDeepAnalysis();
      
      emit(StorageAnalysisCompleted(results: results));
    } catch (e) {
      emit(StorageAnalysisError(
        message: 'Failed to analyze storage: ${e.toString()}',
      ));
    }
  }

  Future<void> _updateProgress(String message, double progress) async {
    emit(StorageAnalysisInProgress(
      message: message,
      progress: progress,
    ));
  }

  void cancelAnalysis() {
    emit(StorageAnalysisCancelled());
  }
}