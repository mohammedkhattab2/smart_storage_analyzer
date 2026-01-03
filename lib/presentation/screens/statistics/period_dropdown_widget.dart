import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class PeriodDropdownWidget extends StatefulWidget {
  final String currentPeriod;
  final List<String> availablePeriods;
  final Function(String?) onPeriodChanged;

  const PeriodDropdownWidget({
    super.key,
    required this.currentPeriod,
    required this.availablePeriods,
    required this.onPeriodChanged,
  });

  @override
  State<PeriodDropdownWidget> createState() => _PeriodDropdownWidgetState();
}

class _PeriodDropdownWidgetState extends State<PeriodDropdownWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSize.paddingMedium,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [
                      colorScheme.primaryContainer.withValues(alpha: .3),
                      colorScheme.primaryContainer.withValues(alpha: 0.1),
                    ]
                  : [
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainer.withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppSize.radiusMedium),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.primary.withValues(alpha: .3)
                  : colorScheme.outlineVariant.withValues(alpha: .5),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: .1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: colorScheme.surfaceContainer,
            ),
            child: DropdownButton<String>(
              value: widget.currentPeriod,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _isPressed = true);
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _isPressed = false);
                });
                widget.onPeriodChanged(value);
              },
              items: widget.availablePeriods.map((period) {
                final isSelected = period == widget.currentPeriod;
                return DropdownMenuItem(
                  value: period,
                  child: Text(
                    period,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
              underline: const SizedBox.shrink(),
              icon: Transform.rotate(
                angle: _isHovered ? 3.14159 : 0,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              dropdownColor: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSize.radiusMedium),
              elevation: isDark ? 8 : 4,
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}
