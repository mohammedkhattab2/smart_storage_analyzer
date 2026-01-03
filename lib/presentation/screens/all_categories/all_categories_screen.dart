import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/domain/entities/category.dart';
import 'package:smart_storage_analyzer/presentation/cubits/all_categories/all_categories_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/all_categories/all_categories_view.dart';

class AllCategoriesScreen extends StatelessWidget {
  final List<Category> categories;

  const AllCategoriesScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AllCategoriesCubit(viewModel: sl())..loadCategories(categories),
      child: const AllCategoriesView(),
    );
  }
}
