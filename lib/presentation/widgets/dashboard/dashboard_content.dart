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
      padding: EdgeInsets.all(AppSize.paddingMedium),
      child: Column(
        children: [
          StorageCircleWidget(storageInfo: state.storageInfo),
          SizedBox(height: AppSize.paddingLarge),
          AnalyzeButton(
            onPressed: () {
              context.read<DashboardCubit>().analyzeAndClean();
            },
          ),
          SizedBox(height: AppSize.paddingLarge),
          DetailsSection(),
          SizedBox(height: AppSize.paddingSmall),
          CategoryGridWidget(
            categories: state.categories,
            onCategoryTap: (category) {
              //TODO: Navigate to category details
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${category.name} files: ${category.fileCount}"),
                  backgroundColor: category.color,
                  duration: const Duration(seconds: 2),
                  )
              );
            },
          ),
        ],
      ),
    );
  }
}
