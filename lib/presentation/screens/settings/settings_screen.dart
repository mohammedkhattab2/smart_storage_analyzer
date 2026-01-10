import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/settings/settings_state.dart';
import 'package:smart_storage_analyzer/presentation/screens/settings/settings_view.dart';
import 'package:smart_storage_analyzer/routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the global SettingsCubit instead of creating a new one
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is SettingsSignedOut) {
          context.go(AppRoutes.onboarding);
        }
      },
      child: const SettingsView(),
    );
  }
}
