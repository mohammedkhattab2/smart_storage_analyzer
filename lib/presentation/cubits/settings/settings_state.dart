import 'package:equatable/equatable.dart';
import 'package:smart_storage_analyzer/domain/entities/settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object> get props => [];
}
class SettingsInitial extends SettingsState {}
class SettingsLoading extends SettingsState {}
class SettingsLoaded extends SettingsState {
  final Settings settings;
  const SettingsLoaded({required this.settings});
  @override
  List<Object> get props => [settings];
}
class SettindsUpdating extends SettingsState {}
class SettingsError extends SettingsState {
  final String message;
  const SettingsError({required this.message});
  @override
  List<Object> get props => [message];
}
class SettingsSigningOut extends SettingsState {}
class SettingsSignedOut extends SettingsState {}

