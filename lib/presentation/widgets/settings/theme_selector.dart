import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/theme/app_theme_mode.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/theme/theme_state.dart';

/// Theme selector widget for settings
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return PopupMenuButton<AppThemeMode>(
          initialValue: state.themeMode,
          onSelected: (mode) {
            context.read<ThemeCubit>().setThemeMode(mode);
          },
          offset: const Offset(0, 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.radiusMedium),
          ),
          itemBuilder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            
            return AppThemeMode.values.map((mode) {
              return PopupMenuItem<AppThemeMode>(
                value: mode,
                child: _ThemeModeOption(
                  mode: mode,
                  isSelected: mode == state.themeMode,
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppSize.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.themeMode.icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  state.themeMode.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
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

  const _ThemeModeOption({
    required this.mode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            mode.icon,
            size: 20,
            color: isSelected 
                ? colorScheme.primary 
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mode.label,
              style: TextStyle(
                color: isSelected 
                    ? colorScheme.primary 
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 20,
              color: colorScheme.primary,
            ),
        ],
      ),
    );
  }
}