import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/category_details/category_details_screen.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/analyze_button.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/category_grid_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/details_section.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/storage_circle_widget.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';

class DashboardContent extends StatelessWidget {
  final DashboardLoaded state;
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
              context.push(AppRoutes.storageAnalysis);
            },
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          DetailsSection(categories: state.categories),
          const SizedBox(height: AppSize.paddingLarge),
          CategoryGridWidget(
            categories: state.categories,
            onCategoryTap: (category) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryDetailsScreen(category: category),
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
