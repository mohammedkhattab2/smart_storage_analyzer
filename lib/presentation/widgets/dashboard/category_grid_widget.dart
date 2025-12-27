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
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveSize.gridColumns(context),
        crossAxisSpacing: AppSize.paddingMedium,
        mainAxisSpacing: AppSize.paddingMedium,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCardWidget(
          category: categories[index],
          onTap: () => onCategoryTap?.call(categories[index]),
          );
      },
    );
  }
}
