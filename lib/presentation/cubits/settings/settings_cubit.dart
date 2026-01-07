import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/domain/usecases/get_settings_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/sign_out_usecase.dart';
import 'package:smart_storage_analyzer/domain/usecases/update_settings_usecase.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_state.dart';
import 'package:smart_storage_analyzer/core/services/notification_service.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettingsUseCase getSettingsUsecase;
  final UpdateSettingsUseCase updateSettingsUsecase;
  final SignOutUseCase signOutUsecase;

  SettingsCubit({
    required this.getSettingsUsecase,
    required this.updateSettingsUsecase,
    required this.signOutUsecase,
  }) : super(SettingsInitial());

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      final settings = await getSettingsUsecase.execute();
      emit(SettingsLoaded(settings: settings));
    } catch (e) {
      emit(SettingsError(message: "Failed to load settings"));
    }
  }

  Future<void> toggleNotifications() async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newValue = !currentSettings.notificationsEnabled;

      emit(
        SettingsLoaded(
          settings: currentSettings.copyWith(notificationsEnabled: newValue),
        ),
      );

      // Schedule or cancel notifications based on the new value
      if (newValue) {
        await NotificationService.instance.scheduleNotifications();
      } else {
        await NotificationService.instance.cancelNotifications();
      }

      await updateSettingsUsecase.updateNotifications(newValue);
    }
  }

  Future<void> toggleDarkMode() async {
    if (state is SettingsLoaded) {
      final currentSettings = (state as SettingsLoaded).settings;
      final newValue = !currentSettings.darkModeEnabled;
      emit(
        SettingsLoaded(
          settings: currentSettings.copyWith(darkModeEnabled: newValue),
        ),
      );
      await updateSettingsUsecase.updateDarkMode(newValue);
    }
  }

  Future<void> signOut() async {
    try {
      await signOutUsecase.execute();
      emit(SettingsSignedOut());
    } catch (e) {
      emit(SettingsError(message: "Failed to sign out"));
    }
  }
}
