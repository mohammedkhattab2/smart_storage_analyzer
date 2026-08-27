import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/whatsapp_scan_result.dart';
import '../../viewmodels/whatsapp_cleaner_viewmodel.dart';
import 'whatsapp_cleaner_state.dart';

class WhatsAppCleanerCubit extends Cubit<WhatsAppCleanerState> {
  final WhatsAppCleanerViewModel _viewModel;

  WhatsAppCleanerCubit(this._viewModel) : super(WhatsAppCleanerInitial());

  void _safeEmit(WhatsAppCleanerState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  Future<void> initialize() async {
    _safeEmit(const WhatsAppScanning(message: 'Checking WhatsApp Folder Access...'));
    final hasPermission = await _viewModel.checkFolderPermission();

    if (isClosed) return;

    if (hasPermission) {
      await scan();
    } else {
      _safeEmit(WhatsAppFolderPermissionRequired());
    }
  }

  Future<void> grantFolderPermission() async {
    _safeEmit(const WhatsAppScanning(message: 'Requesting WhatsApp Folder...'));
    final granted = await _viewModel.requestFolderAccess();

    if (isClosed) return;

    if (granted) {
      await scan();
    } else {
      _safeEmit(WhatsAppFolderPermissionRequired());
    }
  }

  Future<void> scan() async {
    _safeEmit(const WhatsAppScanning(message: 'Scanning WhatsApp media...'));
    try {
      final scanResult = await _viewModel.scanMedia().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('WhatsApp scan took too long. Please try again.');
        },
      );
      if (isClosed) return;
      _safeEmit(WhatsAppLoaded(scanResult: scanResult));
    } catch (e) {
      if (isClosed) return;
      _safeEmit(WhatsAppError('Failed to scan WhatsApp media: ${e.toString()}'));
    }
  }

  void toggleItemSelection(String uri) {
    if (state is! WhatsAppLoaded || isClosed) return;
    final current = (state as WhatsAppLoaded);
    final updated = Set<String>.from(current.selectedUris);

    if (updated.contains(uri)) {
      updated.remove(uri);
    } else {
      updated.add(uri);
    }

    _safeEmit(current.copyWith(selectedUris: updated));
  }

  void selectAll(List<String> uris) {
    if (state is! WhatsAppLoaded || isClosed) return;
    final current = (state as WhatsAppLoaded);
    final updated = Set<String>.from(current.selectedUris)..addAll(uris);
    _safeEmit(current.copyWith(selectedUris: updated));
  }

  void deselectAll() {
    if (state is! WhatsAppLoaded || isClosed) return;
    final current = (state as WhatsAppLoaded);
    _safeEmit(current.copyWith(selectedUris: {}));
  }

  Future<void> deleteSelected() async {
    if (state is! WhatsAppLoaded || isClosed) return;
    final current = (state as WhatsAppLoaded);
    final urisToDelete = current.selectedUris.toList();

    if (urisToDelete.isEmpty) return;

    // Calculate reclaimable bytes for selected items
    int reclaimedBytes = 0;
    for (final item in current.scanResult.allItems) {
      if (urisToDelete.contains(item.uri) || urisToDelete.contains(item.id)) {
        reclaimedBytes += item.sizeBytes;
      }
    }

    _safeEmit(WhatsAppDeleting(totalCount: urisToDelete.length));

    try {
      final deletedCount = await _viewModel.deleteFiles(urisToDelete);

      if (isClosed) return;

      // Immediately filter out deleted items in memory for 0ms UI update
      final remainingItems = current.scanResult.allItems.where((item) {
        return !urisToDelete.contains(item.uri) &&
               !urisToDelete.contains(item.id) &&
               !urisToDelete.contains(item.path);
      }).toList();
      final updatedScanResult = WhatsAppScanResult.fromItems(remainingItems);

      _safeEmit(WhatsAppCleanSuccess(
        deletedFilesCount: deletedCount,
        reclaimedBytes: reclaimedBytes,
      ));

      _safeEmit(WhatsAppLoaded(
        scanResult: updatedScanResult,
        selectedUris: const {},
      ));
    } catch (e) {
      if (isClosed) return;
      _safeEmit(WhatsAppError('Failed to delete files: ${e.toString()}'));
    }
  }

  Future<void> quickCleanRecommended() async {
    if (state is! WhatsAppLoaded || isClosed) return;
    final current = (state as WhatsAppLoaded);

    final recommendedItems = current.scanResult.allItems
        .where((item) => item.isQuickCleanRecommended)
        .toList();

    if (recommendedItems.isEmpty) return;

    final urisToDelete = recommendedItems.map((e) => e.uri).toList();
    final reclaimedBytes = recommendedItems.fold<int>(0, (sum, i) => sum + i.sizeBytes);

    _safeEmit(WhatsAppDeleting(
      totalCount: urisToDelete.length,
      message: 'Quick cleaning Sent media, Statuses & Old Voice notes...',
    ));

    try {
      final deletedCount = await _viewModel.deleteFiles(urisToDelete);

      if (isClosed) return;

      // Immediately filter out deleted items in memory
      final remainingItems = current.scanResult.allItems.where((item) {
        return !urisToDelete.contains(item.uri) &&
               !urisToDelete.contains(item.id) &&
               !urisToDelete.contains(item.path);
      }).toList();
      final updatedScanResult = WhatsAppScanResult.fromItems(remainingItems);

      _safeEmit(WhatsAppCleanSuccess(
        deletedFilesCount: deletedCount,
        reclaimedBytes: reclaimedBytes,
      ));

      _safeEmit(WhatsAppLoaded(
        scanResult: updatedScanResult,
        selectedUris: const {},
      ));
    } catch (e) {
      if (isClosed) return;
      _safeEmit(WhatsAppError('Failed to perform quick clean: ${e.toString()}'));
    }
  }
}
