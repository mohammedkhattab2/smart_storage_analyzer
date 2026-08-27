import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_size.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../domain/entities/whatsapp_media_item.dart';
import '../../cubits/whatsapp_cleaner/whatsapp_cleaner_cubit.dart';
import '../../cubits/whatsapp_cleaner/whatsapp_cleaner_state.dart';
import 'widgets/whatsapp_category_card.dart';
import 'widgets/whatsapp_quick_clean_dialog.dart';
import 'whatsapp_category_detail_screen.dart';

class WhatsAppOverviewScreen extends StatefulWidget {
  const WhatsAppOverviewScreen({super.key});

  @override
  State<WhatsAppOverviewScreen> createState() => _WhatsAppOverviewScreenState();
}

class _WhatsAppOverviewScreenState extends State<WhatsAppOverviewScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WhatsAppCleanerCubit>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Media Cleaner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Select WhatsApp Folder',
            onPressed: () => context.read<WhatsAppCleanerCubit>().grantFolderPermission(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Scan',
            onPressed: () => context.read<WhatsAppCleanerCubit>().scan(),
          ),
        ],
      ),
      body: BlocConsumer<WhatsAppCleanerCubit, WhatsAppCleanerState>(
        listener: (context, state) {
          if (state is WhatsAppCleanSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cleaned ${state.deletedFilesCount} files (${FileSizeFormatter.formatSize(state.reclaimedBytes)}) successfully!',
                ),
                backgroundColor: const Color(0xFF00A884),
              ),
            );
          } else if (state is WhatsAppError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WhatsAppScanning) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A884)),
                  ),
                  const SizedBox(height: AppSize.paddingLarge),
                  Text(
                    state.message,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          if (state is WhatsAppFolderPermissionRequired) {
            return _buildPermissionView(context);
          }

          if (state is WhatsAppLoaded) {
            final scan = state.scanResult;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSize.paddingMedium),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Storage & Quick Clean Card
                  _buildHeroCard(context, scan),
                  if (scan.totalFilesCount == 0) ...[
                    _buildEmptyFolderNotice(context),
                  ],
                  const SizedBox(height: AppSize.paddingLarge),

                  // 2. Categories Section Title
                  Text(
                    'Media Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSize.paddingSmall),

                  // 3. Categories Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSize.paddingSmall,
                      mainAxisSpacing: AppSize.paddingSmall,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: WhatsAppMediaType.values.length,
                    itemBuilder: (context, index) {
                      final type = WhatsAppMediaType.values[index];
                      final summary = scan.categories[type];
                      if (summary == null) return const SizedBox.shrink();

                      return WhatsAppCategoryCard(
                        summary: summary,
                        totalWhatsAppSize: scan.totalSizeBytes,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<WhatsAppCleanerCubit>(),
                                child: WhatsAppCategoryDetailScreen(
                                  categorySummary: summary,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSize.paddingXLarge),

                  // 4. Disclaimer Footer
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSize.paddingMedium),
                      child: Text(
                        'Disclaimer: This feature is an independent storage analyzer and is not affiliated with, endorsed by, or sponsored by WhatsApp LLC or Meta Platforms, Inc.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSize.paddingLarge),
                ],
              ),
            );
          }

          if (state is WhatsAppDeleting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A884)),
                  ),
                  const SizedBox(height: AppSize.paddingLarge),
                  Text(
                    state.message,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          if (state is WhatsAppError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSize.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: AppSize.paddingMedium),
                    Text(
                      'Failed to scan WhatsApp',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSize.paddingSmall),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSize.paddingLarge),
                    FilledButton.icon(
                      onPressed: () => context.read<WhatsAppCleanerCubit>().scan(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00A884),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, dynamic scan) {
    final theme = Theme.of(context);
    final cubit = context.read<WhatsAppCleanerCubit>();

    return Container(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008069), Color(0xFF00A884)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSize.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A884).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total WhatsApp Storage',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FileSizeFormatter.formatSize(scan.totalSizeBytes),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSize.paddingMedium),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: AppSize.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cleanable Clutter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    FileSizeFormatter.formatSize(scan.cleanableSizeBytes),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (scan.cleanableSizeBytes > 0)
                FilledButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => WhatsAppQuickCleanDialog(
                        scanResult: scan,
                        onConfirm: () => cubit.quickCleanRecommended(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF008069),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSize.radiusMedium),
                    ),
                  ),
                  icon: const Icon(Icons.auto_delete_rounded, size: 18),
                  label: const Text('Quick Clean'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFolderNotice(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<WhatsAppCleanerCubit>();

    return Container(
      margin: const EdgeInsets.only(top: AppSize.paddingMedium),
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSize.radiusLarge),
        border: Border.all(
          color: const Color(0xFF00A884).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A884).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF00A884),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSize.paddingSmall),
              Expanded(
                child: Text(
                  'No WhatsApp files found?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSize.paddingSmall),
          Text(
            'On Android 11+, WhatsApp media requires folder permission. Tap below to select and grant access to the "Android > media > com.whatsapp" folder.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSize.paddingMedium),
          FilledButton.icon(
            onPressed: () => cubit.grantFolderPermission(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSize.radiusMedium),
              ),
            ),
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('Select WhatsApp Folder'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = context.read<WhatsAppCleanerCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSize.paddingMedium),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00A884).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_shared_rounded,
              size: 56,
              color: Color(0xFF00A884),
            ),
          ),
          const SizedBox(height: AppSize.paddingMedium),
          Text(
            'Select WhatsApp Folder',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSize.paddingSmall),
          Text(
            'Follow these 3 quick steps in the file picker:',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSize.paddingMedium),

          // Steps Guide Card
          Container(
            padding: const EdgeInsets.all(AppSize.paddingMedium),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSize.radiusLarge),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildStepRow(
                  context,
                  stepNumber: '1',
                  text: 'Click the "Grant Access" button below.',
                  icon: Icons.touch_app_rounded,
                ),
                const Divider(height: 16),
                _buildStepRow(
                  context,
                  stepNumber: '2',
                  text: 'Navigate to: Android  >  media  >  com.whatsapp',
                  icon: Icons.folder_rounded,
                  highlight: true,
                ),
                const Divider(height: 16),
                _buildStepRow(
                  context,
                  stepNumber: '3',
                  text: 'Tap "Use this folder" at the bottom & tap Allow.',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSize.paddingXLarge),
          FilledButton.icon(
            onPressed: () => cubit.grantFolderPermission(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSize.radiusMedium),
              ),
            ),
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text(
              'Grant Access & Select Folder',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: AppSize.paddingMedium),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context, {
    required String stepNumber,
    required String text,
    required IconData icon,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight
                ? const Color(0xFF00A884)
                : colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            stepNumber,
            style: TextStyle(
              color: highlight ? Colors.white : colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? const Color(0xFF00A884) : colorScheme.onSurface,
            ),
          ),
        ),
        Icon(
          icon,
          size: 20,
          color: highlight ? const Color(0xFF00A884) : colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}
