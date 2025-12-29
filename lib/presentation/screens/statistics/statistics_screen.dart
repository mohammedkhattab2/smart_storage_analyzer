import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/service_locator/service_locator.dart';
import 'package:smart_storage_analyzer/presentation/cubits/statistics/statistics_cubit.dart';
import 'package:smart_storage_analyzer/presentation/screens/statistics/statistics_view.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<StatisticsCubit>()..loadStatistics(),
      child: 
         const StatisticsView(),
         
      
      );
  }
}