import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/theme/app_color_schemes.dart';
import 'package:smart_storage_analyzer/core/utils/size_formatter.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';

class CategoryCardWidget extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  const CategoryCardWidget({super.key , required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLargeCategory = category.sizeInBytes > 1000000000; // 1GB
    
    // Get category color based on theme
    final categoryColor = _getCategoryColor(context, category);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSize.radiusLarge),
            border: Border.all(
              color: categoryColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSize.paddingMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSize.radiusMedium),
                  ),
                  child: Icon(
                    category.icon,
                    size: AppSize.iconMedium + 4,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(height: AppSize.paddingSmall + 4),
                // Category name
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: AppSize.fontLarge,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Size badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSize.paddingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isLargeCategory
                        ? colorScheme.warningContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSize.radiusSmall),
                  ),
                  child: Text(
                    SizeFormatter.formateBytes(category.sizeInBytes.toInt()),
                    style: TextStyle(
                      fontSize: AppSize.fontSmall + 1,
                      color: isLargeCategory
                          ? colorScheme.warning
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // File count
                Text(
                  '${category.fileCount} files',
                  style: TextStyle(
                    fontSize: AppSize.fontSmall,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getCategoryColor(BuildContext context, Category category) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Use the category extensions from AppColorSchemes
    switch (category.name.toLowerCase()) {
      case 'images':
      case 'image':
        return colorScheme.imageCategory;
      case 'videos':
      case 'video':
        return colorScheme.videoCategory;
      case 'audio':
      case 'music':
        return colorScheme.audioCategory;
      case 'documents':
      case 'document':
        return colorScheme.documentCategory;
      case 'apps':
      case 'applications':
        return colorScheme.appsCategory;
      case 'others':
      case 'other':
      default:
        return colorScheme.othersCategory;
    }
  }
}
