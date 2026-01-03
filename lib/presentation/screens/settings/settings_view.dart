import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/models/settings_item_model.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/settings_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/loading_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/settings_header.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/settings_section.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/settings_tile.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/sign_out_button.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/theme_selector.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/premium_card.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        ),
      ),
      body: SafeArea(
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

              final sections = viewModel.getSections();

              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await cubit.loadSettings();
                },
                color: colorScheme.primary,
                backgroundColor: colorScheme.surface,
                displacement: 80,
                strokeWidth: 3,
                triggerMode: RefreshIndicatorTriggerMode.onEdge,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
                  slivers: [
                    // Header
                    const SliverToBoxAdapter(
                      child: SettingsHeader(),
                    ),

                    // Premium Card
                    if (!state.settings.isPremiumUser)
                      SliverToBoxAdapter(
                        child: PremiumCard(
                          isPremium: state.settings.isPremiumUser,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            // Handle premium upgrade
                          },
                        ),
                      ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSize.paddingMedium),
                    ),

                    // Settings Sections
                    SliverList(
                      delegate: SliverChildBuilderDelegate((
                        context,
                        sectionIndex,
                      ) {
                        final section = sections[sectionIndex];
                        return _buildSection(
                          context,
                          section,
                          sectionIndex,
                          viewModel,
                        );
                      }, childCount: sections.length),
                    ),

                    // Sign Out Button
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSize.paddingLarge,
                          AppSize.paddingXLarge,
                          AppSize.paddingLarge,
                          AppSize.paddingXLarge * 2,
                        ),
                        child: SignOutButton(
                          onTap: viewModel.showSignOutDialog,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    dynamic section,
    int sectionIndex,
    SettingsViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSize.paddingMedium),
      child: SettingsSection(
        title: section.title,
        children: _buildSectionItems(context, section.items),
      ),
    );
  }

  List<Widget> _buildSectionItems(
    BuildContext context,
    List<SettingsItemModel> items,
  ) {
    final widgets = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      widgets.add(_buildSettingsTile(context, item));
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
    final colorScheme = Theme.of(context).colorScheme;

    switch (item.type) {
      case SettingsItemType.toggle:
        trailing = Switch.adaptive(
          value: item.value ?? false,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            item.onToggle?.call(value);
          },
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.outline;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary.withValues(alpha: .5);
            }
            return colorScheme.surfaceContainerHighest;
          }),
        );
        break;

      case SettingsItemType.navigation:
        trailing = Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: .1),
                colorScheme.primary.withValues(alpha: .05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: colorScheme.primary,
          ),
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
