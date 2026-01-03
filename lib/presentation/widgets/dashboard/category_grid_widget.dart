import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/utils/responsive.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/presentation/widgets/dashboard/category_card_widget.dart';

class CategoryGridWidget extends StatelessWidget {
  final List<Category> categories;
  final Function(Category)? onCategoryTap;
  const CategoryGridWidget({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveSize.gridColumns(context);

    return Container(
      padding: const EdgeInsets.only(top: AppSize.paddingSmall),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth =
              (constraints.maxWidth - AppSize.paddingMedium * (columns - 1)) /
              columns;
          final aspectRatio =
              itemWidth / (itemWidth * 0.92); // Slightly taller cards

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSize.paddingMedium,
              mainAxisSpacing: AppSize.paddingMedium,
              childAspectRatio: aspectRatio,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return CategoryCardWidget(
                category: categories[index],
                onTap: () => onCategoryTap?.call(
                  categories[index],
                ),
                index: index,
              );
            },
          );
        },
      ),
    );
  }
}
