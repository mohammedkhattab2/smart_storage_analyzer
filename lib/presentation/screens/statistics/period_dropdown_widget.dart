import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class PeriodDropdownWidget extends StatelessWidget {
  final String currentPeriod;
  final List<String> availablePeriods;
  final Function(String?) onPeriodCahnged;
  const PeriodDropdownWidget({
    super.key,
    required this.currentPeriod,
    required this.availablePeriods,
    required this.onPeriodCahnged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.paddingMedium,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.paddingSmall),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: currentPeriod,
        onChanged: onPeriodCahnged,
        items: availablePeriods.map((period) {
          return DropdownMenuItem(
            value: period,
            child: Text(
              period, 
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSize.fontSmall
              ),
            )
            );
        }).toList(),
        underline: SizedBox.shrink(),
        icon: Icon(
          Icons.arrow_drop_down,
          color: AppColors.textSecondary ,
          size: 20,
        ),
        dropdownColor: AppColors.cardBackground,
        isDense: true,
      ),
    );
  }
}
