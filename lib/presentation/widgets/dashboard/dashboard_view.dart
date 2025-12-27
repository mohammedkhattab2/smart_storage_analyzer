import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/dashboard/dashboard_state.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<DashboardCubit, DashboardState>(
          builder: (context, State) {
            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().refresh(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(children: [_buildHeader(context)]),
              ),
            );
          },
          listener: (context, state) {
            if (state is DashboardError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.dashboard,
              style: TextStyle(
                fontSize: AppSize.fontXXLarge,
                fontWeight:  FontWeight.bold,
                color: AppColors.primary,
              ),
              ),
              IconButton(
                onPressed: (){}, 
                icon: Icon(Icons.more_vert,
                color: AppColors.textPrimary,),
                ),
            ],
            
          ),
          Text(AppStrings.deviceStorageOverview,
          style: TextStyle(
            fontSize:  AppSize.fontMedium,
            color: AppColors.textSecondary
          ),
          )


        ],
      ),
      );
  }
}
