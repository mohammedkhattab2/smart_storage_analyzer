import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';
import 'package:smart_storage_analyzer/domain/entities/settings.dart';
import 'package:smart_storage_analyzer/presentation/models/settings_item_model.dart';

/// ViewModel for Settings screen following MVVM pattern
/// Contains only business logic, no UI-specific code
class SettingsViewModel {
  final Settings settings;
  final Function() onToggleNotifications;
  final Function() onToggleDarkMode;
  final Function() onSignOut;
  final Function() onNavigateToPrivacyPolicy;
  final Function() onNavigateToTermsOfService;
  final Function() onNavigateToAbout;
  final Function() onRequestSignOut; // Request sign out confirmation

  SettingsViewModel({
    required this.settings,
    required this.onToggleNotifications,
    required this.onToggleDarkMode,
    required this.onSignOut,
    required this.onNavigateToPrivacyPolicy,
    required this.onNavigateToTermsOfService,
    required this.onNavigateToAbout,
    required this.onRequestSignOut,
  });

  List<SettingsSectionModel> getSections() {
    return [
      SettingsSectionModel(
        title: AppStrings.general,
        items: [
          SettingsItemModel(
            id: 'notifications',
            icon: Icons.notifications_outlined,
            title: AppStrings.notifications,
            type: SettingsItemType.toggle,
            value: settings.notificationsEnabled,
            onToggle: (_) => onToggleNotifications(),
          ),
          SettingsItemModel(
            id: 'dark_mode',
            icon: Icons.dark_mode_outlined,
            title: AppStrings.darkMode,
            type: SettingsItemType.toggle,
            value: settings.darkModeEnabled,
            onToggle: (_) => onToggleDarkMode(),
          ),
        ],
      ),
      SettingsSectionModel(
        title: AppStrings.legal,
        items: [
          SettingsItemModel(
            id: 'privacy_policy',
            icon: Icons.privacy_tip_outlined,
            title: AppStrings.privacyPolicy,
            type: SettingsItemType.navigation,
            onTap: onNavigateToPrivacyPolicy,
          ),
          SettingsItemModel(
            id: 'terms_of_service',
            icon: Icons.description_outlined,
            title: AppStrings.termsOfService,
            type: SettingsItemType.navigation,
            onTap: onNavigateToTermsOfService,
          ),
          SettingsItemModel(
            id: 'about',
            icon: Icons.info_outline,
            title: AppStrings.about,
            type: SettingsItemType.navigation,
            onTap: onNavigateToAbout,
          ),
        ],
      ),
    ];
  }

  /// Check if user is signed in (business logic)
  bool get isUserSignedIn {
    // This would check authentication state
    // For now, return true
    return true;
  }

  /// Get app version (business logic)
  String get appVersion {
    return "1.0.0"; // Would be fetched from package info
  }
}
