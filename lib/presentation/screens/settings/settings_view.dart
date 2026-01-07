import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/presentation/models/settings_item_model.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/settings_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/widgets/settings/theme_selector.dart';
// Removed unused import: app_routes.dart
import 'package:smart_storage_analyzer/presentation/screens/settings/privacy_policy_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/settings/terms_of_service_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/settings/about_screen.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha: 0.02),
              colorScheme.secondary.withValues(alpha: 0.03),
              colorScheme.tertiary.withValues(alpha: 0.02),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Magical background orbs
            _buildMagicalBackground(context),

            SafeArea(
              child: BlocConsumer<SettingsCubit, SettingsState>(
                listener: (context, state) {
                  if (state is SettingsSignedOut) {
                    // Close the app when signed out
                    SystemNavigator.pop();
                  }
                },
                builder: (context, state) {
                  if (state is SettingsLoading) {
                    return Center(child: _buildMagicalLoadingWidget(context));
                  }

                  if (state is SettingsLoaded) {
                    final cubit = context.read<SettingsCubit>();
                    final viewModel = SettingsViewModel(
                      settings: state.settings,
                      onToggleNotifications: cubit.toggleNotifications,
                      onToggleDarkMode: cubit.toggleDarkMode,
                      onSignOut: cubit.signOut,
                      onNavigateToPrivacyPolicy: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      onNavigateToTermsOfService: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                      },
                      onNavigateToAbout: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                      onRequestSignOut: () {
                        _SettingsViewHelpers.showSignOutDialog(context, cubit);
                      },
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
                          // Magical Header
                          SliverToBoxAdapter(
                            child: _buildMagicalHeader(context),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: AppSize.paddingLarge),
                          ),

                          // Settings Sections with magical styling
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              sectionIndex,
                            ) {
                              final section = sections[sectionIndex];
                              return _buildMagicalSection(
                                context,
                                section,
                                sectionIndex,
                                viewModel,
                              );
                            }, childCount: sections.length),
                          ),

                          // Magical Sign Out Button
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSize.paddingLarge,
                                AppSize.paddingXLarge,
                                AppSize.paddingLarge,
                                AppSize.paddingXLarge * 2,
                              ),
                              child: _buildMagicalSignOutButton(
                                context,
                                viewModel.onRequestSignOut,
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
          ],
        ),
      ),
    );
  }

  Widget _buildMagicalBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Top left orb
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom right orb
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.secondary.withValues(alpha: 0.06),
                  colorScheme.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Center accent
        Positioned(
          top: size.height * 0.4,
          left: size.width * 0.7,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.tertiary.withValues(alpha: 0.05),
                  colorScheme.tertiary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Decorative lines
        CustomPaint(
          size: size,
          painter: _SettingsBackgroundPainter(
            primaryColor: colorScheme.primary.withValues(alpha: 0.02),
            secondaryColor: colorScheme.secondary.withValues(alpha: 0.02),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalLoadingWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.primary.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              Icon(Icons.settings, size: 32, color: colorScheme.primary),
            ],
          ),
        ),
        const SizedBox(height: AppSize.paddingLarge),
        Text(
          'Loading Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMagicalHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            colorScheme.secondary.withValues(alpha: 0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.primary.withValues(alpha: 0.08),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.settings_rounded,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSize.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ).createShader(bounds),
                      child: Text(
                        'Settings',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'Customize your experience',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalSection(
    BuildContext context,
    dynamic section,
    int sectionIndex,
    SettingsViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Different gradient colors for each section
    final gradientColors = [
      [colorScheme.primary, colorScheme.secondary],
      [colorScheme.secondary, colorScheme.tertiary],
      [colorScheme.tertiary, colorScheme.primary],
    ];

    final colors = gradientColors[sectionIndex % gradientColors.length];

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSize.paddingLarge,
        0,
        AppSize.paddingLarge,
        AppSize.paddingLarge,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[0].withValues(alpha: 0.05),
            colors[1].withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[0].withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSize.paddingLarge,
              AppSize.paddingMedium,
              AppSize.paddingLarge,
              AppSize.paddingSmall,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors[0].withValues(alpha: 0.1),
                  colors[1].withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSize.paddingMedium),
                Text(
                  section.title,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...section.items.asMap().entries.map<Widget>((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildMagicalSettingsTile(
              context,
              item,
              index == section.items.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMagicalSettingsTile(
    BuildContext context,
    SettingsItemModel item,
    bool isLast,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Special handling for theme selector
    if (item.id == 'dark_mode' || item.id == 'theme_mode') {
      return Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(AppSize.paddingLarge),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.primary.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.dark_mode_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSize.paddingMedium),
                Text(
                  'Appearance',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const ThemeSelector(),
              ],
            ),
          ),
        ),
      );
    }

    Widget? trailing;

    switch (item.type) {
      case SettingsItemType.toggle:
        trailing = _buildMagicalSwitch(
          context,
          value: item.value ?? false,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            item.onToggle?.call(value);
          },
        );
        break;

      case SettingsItemType.navigation:
        trailing = Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.secondary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: colorScheme.primary,
          ),
        );
        break;

      case SettingsItemType.action:
        trailing = null;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: item.onTap != null && item.type == SettingsItemType.navigation
            ? colorScheme.primary.withValues(alpha: 0.02)
            : Colors.transparent,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                )
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSize.paddingLarge),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.08),
                        colorScheme.primary.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: AppSize.paddingMedium),
                Expanded(
                  child: Text(
                    item.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagicalSwitch(
    BuildContext context, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: value
                ? colorScheme.primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
    );
  }

  Widget _buildMagicalSignOutButton(BuildContext context, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.error.withValues(alpha: 0.1),
            colorScheme.error.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.error.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSize.paddingMedium + 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.error.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.error.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSize.paddingMedium),
                Text(
                  'Sign Out',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for decorative background
class _SettingsBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _SettingsBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw curved lines
    paint.color = primaryColor;
    final path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.15,
      size.width,
      size.height * 0.25,
    );
    canvas.drawPath(path1, paint);

    paint.color = secondaryColor;
    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.6);
    path2.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.65,
      0,
      size.height * 0.55,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper class for UI operations
class _SettingsViewHelpers {
  static void showSignOutDialog(BuildContext context, SettingsCubit cubit) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSize.paddingLarge),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.error.withValues(alpha: 0.1),
                        colorScheme.error.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.error.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: colorScheme.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSize.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign Out',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Are you sure you want to sign out?',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSize.paddingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSize.paddingLarge,
                            vertical: AppSize.paddingMedium,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSize.paddingSmall),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          HapticFeedback.mediumImpact();
                          cubit.signOut();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSize.paddingLarge,
                            vertical: AppSize.paddingMedium,
                          ),
                        ),
                        child: Text(
                          'Sign Out',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
