import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.storageHistory,
          style: TextStyle(
            fontSize: AppSize.fontLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary
          ),
        ),
        PeriodDropdownWidget(
          currentPeriod: currentPeriod, 
          availablePeriods: availablePeriods, 
          onPeriodCahnged: onPeriodChanged
          )
      ],
    );
  }
}
