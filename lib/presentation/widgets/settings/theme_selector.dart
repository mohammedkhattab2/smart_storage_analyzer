import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/theme/app_theme_mode.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_state.dart';

/// Theme selector widget for settings
class ThemeSelector extends StatefulWidget {
  const ThemeSelector({super.key});

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  bool _isOpen = false;

  void _handleMenuOpen() {
    setState(() => _isOpen = true);
  }

  void _handleMenuClose() {
    setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return PopupMenuButton<AppThemeMode>(
          initialValue: state.themeMode,
          onSelected: (mode) {
            HapticFeedback.lightImpact();
            context.read<ThemeCubit>().setThemeMode(mode);
          },
          onOpened: _handleMenuOpen,
          onCanceled: _handleMenuClose,
          offset: const Offset(0, 8),
          elevation: 8,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: colorScheme.surfaceContainer,
          itemBuilder: (context) {
            return AppThemeMode.values.map((mode) {
              return PopupMenuItem<AppThemeMode>(
                value: mode,
                height: 48,
                child: _ThemeModeOption(
                  mode: mode,
                  isSelected: mode == state.themeMode,
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isOpen
                    ? [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withValues(alpha: 0.8),
                      ]
                    : [
                        colorScheme.secondaryContainer.withValues(alpha: 0.8),
                        colorScheme.secondaryContainer.withValues(alpha: 0.6),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isOpen
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isOpen ? colorScheme.primary : colorScheme.shadow)
                      .withValues(alpha: 0.1),
                  blurRadius: _isOpen ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.themeMode.icon,
                  key: ValueKey(state.themeMode),
                  size: 20,
                  color: _isOpen
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  state.themeMode.label,
                  style: textTheme.labelLarge!.copyWith(
                    color: _isOpen
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 22,
                  color: _isOpen
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Individual theme mode option in the popup menu
class _ThemeModeOption extends StatelessWidget {
  final AppThemeMode mode;
  final bool isSelected;

  const _ThemeModeOption({required this.mode, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              mode.icon,
              size: 18,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mode.label,
              style: textTheme.bodyMedium!.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 14,
                color: colorScheme.onPrimary,
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
