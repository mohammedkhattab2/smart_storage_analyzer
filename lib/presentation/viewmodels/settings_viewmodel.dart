import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';
import 'package:smart_storage_analyzer/domain/entities/settings.dart';
import 'package:smart_storage_analyzer/domain/models/settings_item_model.dart';
import 'package:smart_storage_analyzer/presentation/screens/settings/privacy_policy_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/settings/terms_of_service_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/settings/about_screen.dart';

class SettingsViewModel {
  final BuildContext context;
  final Settings settings;
  final Function() onToggleNotifications;
  final Function() onToggleDarkMode;
  final Function() onSignOut;

  SettingsViewModel({
    required this.context,
    required this.settings,
    required this.onToggleNotifications,
    required this.onToggleDarkMode,
    required this.onSignOut,
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
            onTap: () => navigateToPrivacyPolicy(),
          ),
          SettingsItemModel(
            id: 'terms_of_service',
            icon: Icons.description_outlined,
            title: AppStrings.termsOfService,
            type: SettingsItemType.navigation,
            onTap: () => navigateToTermsOfService(),
          ),
          SettingsItemModel(
            id: 'about',
            icon: Icons.info_outline,
            title: AppStrings.about,
            type: SettingsItemType.navigation,
            onTap: () => navigateToAbout(),
          ),
        ],
      ),
    ];
  }

  void navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void navigateToTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  void navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  void showPremium() {
    // TODO: Implement premium screen navigation
  }

  void showSignOutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onSignOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
