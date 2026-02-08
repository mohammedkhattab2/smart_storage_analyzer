import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/services/saf_media_scanner_service.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';
import 'package:smart_storage_analyzer/presentation/cubits/document_scan/document_scan_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/category_details/category_details_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/document_scanner/document_scanner_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/media_scanner/media_scanner_screen.dart';
import 'package:smart_storage_analyzer/presentation/screens/others_scanner/others_scanner_screen.dart';
import 'package:smart_storage_analyzer/presentation/cubits/others_scan/others_scan_cubit.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/analyze_button.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/category_grid_widget.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/details_section.dart';
import 'package:smart_storage_analyzer/presentation/widgets/charts/storage_pie_chart.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';

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
          StoragePieChart(
            usedSpaceGb: state.storageInfo.usedSpace / (1024 * 1024 * 1024),
            freeSpaceGb:
                (state.storageInfo.totalSpace - state.storageInfo.usedSpace) /
                (1024 * 1024 * 1024),
          ),
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
              final categoryName = category.name.toLowerCase();
              
              // Check if this is a media category (Images, Videos, Audio)
              // These require SAF-based scanning due to policy compliance
              if (categoryName == 'images' || categoryName == 'image') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MediaScannerScreen(
                      mediaType: MediaType.images,
                      categoryName: 'Images',
                    ),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    context.read<DashboardCubit>().refresh(context: context);
                  }
                });
              } else if (categoryName == 'videos' || categoryName == 'video') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MediaScannerScreen(
                      mediaType: MediaType.videos,
                      categoryName: 'Videos',
                    ),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    context.read<DashboardCubit>().refresh(context: context);
                  }
                });
              } else if (categoryName == 'audio' || categoryName == 'music') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MediaScannerScreen(
                      mediaType: MediaType.audio,
                      categoryName: 'Audio',
                    ),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    context.read<DashboardCubit>().refresh(context: context);
                  }
                });
              } else if (categoryName == 'documents' || categoryName == 'document') {
                // Navigate to DocumentScannerScreen with BLoC provider
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => sl<DocumentScanCubit>()..checkSavedFolder(),
                      child: const DocumentScannerScreen(),
                    ),
                  ),
                ).then((_) {
                  // Refresh dashboard when returning from document scanner
                  // This will update the Documents category with SAF data
                  if (context.mounted) {
                    context.read<DashboardCubit>().refresh(context: context);
                  }
                });
              } else if (categoryName == 'others' || categoryName == 'other') {
                // Navigate to OthersScannerScreen with BLoC provider
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (context) => sl<OthersScanCubit>()..checkSavedFolder(),
                      child: const OthersScannerScreen(),
                    ),
                  ),
                ).then((_) {
                  // Refresh dashboard when returning from others scanner
                  // This will update the Others category with SAF data
                  if (context.mounted) {
                    context.read<DashboardCubit>().refresh(context: context);
                  }
                });
              } else {
                // Navigate to regular category details
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailsScreen(category: category),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: AppSize.paddingMedium),
        ],
      ),
    );
  }
}
