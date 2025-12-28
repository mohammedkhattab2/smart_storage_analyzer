import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/analyze_button.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/category_grid_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/details_section.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/storage_circle_widget.dart';

class DashboardContent extends StatelessWidget {
  final dashboardLoaded state;
  const DashboardContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSize.paddingMedium,
        0,
        AppSize.paddingMedium,
        AppSize.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSize.paddingSmall),
          StorageCircleWidget(storageInfo: state.storageInfo),
          const SizedBox(height: AppSize.paddingXLarge),
          AnalyzeButton(
            onPressed: () {
              context.read<DashboardCubit>().analyzeAndClean();
            },
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          const DetailsSection(),
          const SizedBox(height: AppSize.paddingLarge),
          CategoryGridWidget(
            categories: state.categories,
            onCategoryTap: (category) {
              // TODO: Navigate to category details
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text("${category.name} files: ${category.fileCount}"),
                    backgroundColor: category.color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSize.radiusSmall),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
            },
          ),
          const SizedBox(height: AppSize.paddingMedium),
        ],
      ),
    );
  }
}
