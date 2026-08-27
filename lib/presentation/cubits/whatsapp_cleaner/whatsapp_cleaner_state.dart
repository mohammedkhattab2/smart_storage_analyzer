import 'package:equatable/equatable.dart';
import '../../../domain/entities/whatsapp_scan_result.dart';

abstract class WhatsAppCleanerState extends Equatable {
  const WhatsAppCleanerState();

  @override
  List<Object?> get props => [];
}

class WhatsAppCleanerInitial extends WhatsAppCleanerState {}

class WhatsAppFolderPermissionRequired extends WhatsAppCleanerState {}

class WhatsAppScanning extends WhatsAppCleanerState {
  final String message;

  const WhatsAppScanning({this.message = 'Scanning WhatsApp Media...'});

  @override
  List<Object?> get props => [message];
}

class WhatsAppLoaded extends WhatsAppCleanerState {
  final WhatsAppScanResult scanResult;
  final Set<String> selectedUris;

  const WhatsAppLoaded({
    required this.scanResult,
    this.selectedUris = const {},
  });

  WhatsAppLoaded copyWith({
    WhatsAppScanResult? scanResult,
    Set<String>? selectedUris,
  }) {
    return WhatsAppLoaded(
      scanResult: scanResult ?? this.scanResult,
      selectedUris: selectedUris ?? this.selectedUris,
    );
  }

  @override
  List<Object?> get props => [scanResult, selectedUris];
}

class WhatsAppDeleting extends WhatsAppCleanerState {
  final int totalCount;
  final String message;

  const WhatsAppDeleting({
    required this.totalCount,
    this.message = 'Cleaning selected files...',
  });

  @override
  List<Object?> get props => [totalCount, message];
}

class WhatsAppCleanSuccess extends WhatsAppCleanerState {
  final int deletedFilesCount;
  final int reclaimedBytes;

  const WhatsAppCleanSuccess({
    required this.deletedFilesCount,
    required this.reclaimedBytes,
  });

  @override
  List<Object?> get props => [deletedFilesCount, reclaimedBytes];
}

class WhatsAppError extends WhatsAppCleanerState {
  final String message;

  const WhatsAppError(this.message);

  @override
  List<Object?> get props => [message];
}
