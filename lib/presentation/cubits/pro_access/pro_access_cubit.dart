import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/presentation/cubits/pro_access/pro_access_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/pro_access_viewmodel.dart';

/// Cubit for managing Pro access state in the UI
class ProAccessCubit extends Cubit<ProAccessState> {
  final ProAccessViewModel _viewModel;
  
  ProAccessCubit({required ProAccessViewModel viewModel})
      : _viewModel = viewModel,
        super(ProAccessInitial());
  
  /// Load Pro access state
  Future<void> loadProAccess() async {
    emit(ProAccessLoading());
    
    try {
      final proAccess = await _viewModel.getProAccess();
      emit(ProAccessLoaded(proAccess: proAccess));
    } catch (e) {
      emit(ProAccessError(message: 'Failed to load Pro access'));
    }
  }
  
  /// Check if a specific feature is available
  Future<bool> checkFeature(String featureName) async {
    try {
      return await _viewModel.hasFeature(featureName);
    } catch (e) {
      return false;
    }
  }
  
  /// Show Pro feature dialog
  void showProFeatureInfo() {
    if (state is ProAccessLoaded) {
      emit(ProAccessShowingInfo(
        proAccess: (state as ProAccessLoaded).proAccess,
      ));
    }
  }
  
  /// Dismiss Pro feature info
  void dismissProFeatureInfo() {
    if (state is ProAccessShowingInfo) {
      emit(ProAccessLoaded(
        proAccess: (state as ProAccessShowingInfo).proAccess,
      ));
    }
  }
  
  /// Refresh Pro access
  Future<void> refresh() async {
    await _viewModel.refreshProAccess();
    await loadProAccess();
  }
}