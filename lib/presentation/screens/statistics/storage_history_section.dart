import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/period_dropdown_widget.dart';

class StorageHistorySection extends StatelessWidget {
  final String currentPeriod;
  final List<String> availablePeriods;
  final Function(String?) onPeriodChanged;

  const StorageHistorySection({
    super.key,
    required this.currentPeriod,
    required this.availablePeriods,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.storageHistory,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Analyze your storage trends',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSize.paddingMedium),
        PeriodDropdownWidget(
          currentPeriod: currentPeriod,
          availablePeriods: availablePeriods,
          onPeriodChanged: onPeriodChanged,
        ),
      ],
    );
  }
}
