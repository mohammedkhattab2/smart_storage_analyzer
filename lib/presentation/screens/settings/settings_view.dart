import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/models/settings_item_model.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/settings_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/premium_card.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/settings_header.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/settings_section.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/settings_tile.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/sign_out_button.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/theme_selector.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSize.paddingSmall),
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoading) {
                return const Center(child: LoadingWidget());
              }
              
              if (state is SettingsLoaded) {
                final cubit = context.read<SettingsCubit>();
                final viewModel = SettingsViewModel(
                  context: context,
                  settings: state.settings,
                  onToggleNotifications: cubit.toggleNotifications,
                  onToggleDarkMode: cubit.toggleDarkMode,
                  onSignOut: cubit.signOut,
                );

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SettingsHeader(),
                      const SizedBox(height: AppSize.paddingSmall),
                      PremiumCard(
                        isPremium: state.settings.isPremiumUser,
                        onTap: viewModel.showPremium,
                      ),
                      const SizedBox(height: AppSize.paddingMedium),
                      ..._buildSections(context, viewModel),
                      const SizedBox(height: AppSize.paddingXLarge),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSize.paddingMedium,
                        ),
                        child: SignOutButton(
                          onTap: viewModel.showSignOutDialog,
                        ),
                      ),
                      const SizedBox(height: AppSize.paddingLarge),
                    ],
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, SettingsViewModel viewModel) {
    final sections = viewModel.getSections();
    final widgets = <Widget>[];

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      widgets.add(
        SettingsSection(
          title: section.title,
          children: _buildSectionItems(context, section.items),
        ),
      );

      if (i < sections.length - 1) {
        widgets.add(const SizedBox(height: AppSize.paddingMedium));
      }
    }

    return widgets;
  }

  List<Widget> _buildSectionItems(BuildContext context, List<SettingsItemModel> items) {
    final widgets = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      widgets.add(_buildSettingsTile(context, item));

      if (i < items.length - 1) {
        widgets.add(const SizedBox(height: AppSize.paddingSmall));
      }
    }

    return widgets;
  }

  Widget _buildSettingsTile(BuildContext context, SettingsItemModel item) {
    // Special handling for theme selector
    if (item.id == 'dark_mode' || item.id == 'theme_mode') {
      return SettingsTile(
        icon: Icons.dark_mode_outlined,
        title: 'Appearance',
        trailing: const ThemeSelector(),
        onTap: null,
      );
    }

    Widget? trailing;

    switch (item.type) {
      case SettingsItemType.toggle:
        trailing = Switch.adaptive(
          value: item.value ?? false,
          onChanged: item.onToggle,
          activeColor: Theme.of(context).colorScheme.primary,
        );
        break;
      case SettingsItemType.navigation:
        trailing = Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
        break;
      case SettingsItemType.action:
        trailing = null;
        break;
    }

    return SettingsTile(
      icon: item.icon,
      title: item.title,
      trailing: trailing,
      onTap: item.onTap,
    );
  }
}
