import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    ('Last Updated', 'January 1, 2026'),
    (
      'Introduction',
      'Smart Storage Analyzer ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we handle your information when you use our mobile application.',
    ),
    (
      'Information We Don\'t Collect',
      'Smart Storage Analyzer is designed with privacy in mind:\n\n'
          '• We do NOT collect personal information\n'
          '• We do NOT track your usage\n'
          '• We do NOT share data with third parties\n'
          '• We do NOT use analytics or advertising',
    ),
    (
      'Local Storage Analysis',
      'Our app analyzes your device storage locally:\n\n'
          '• All processing happens on your device\n'
          '• No data leaves your device\n'
          '• Storage information is not transmitted anywhere\n'
          '• We only read storage to display statistics',
    ),
    (
      'Permissions',
      'We request storage permission to:\n\n'
          '• Read storage statistics\n'
          '• Analyze file categories\n'
          '• Calculate storage usage\n\n'
          'This permission is used solely for the app\'s core functionality.',
    ),
    (
      'Data Security',
      'Since we don\'t collect or transmit any data, there\'s no risk of data breaches. All operations are performed locally on your device.',
    ),
    (
      'Children\'s Privacy',
      'Our app does not collect information from anyone, including children under 13 years of age.',
    ),
    (
      'Changes to This Policy',
      'We may update this Privacy Policy from time to time. Any changes will be reflected in the app with an updated revision date.',
    ),
    (
      'Contact Us',
      'If you have any questions about this Privacy Policy, please contact us at:\n\ndimakhattab2017@gmail.com',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        title: Text(
          'Privacy Policy',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.withValues(
                    alpha: isDark ? .3 : .6,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: .1),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSize.paddingLarge),
          child: Column(
            children: [
              const SizedBox(height: AppSize.paddingLarge),
              // Header icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(
                        alpha: isDark ? .3 : .5,
                      ),
                      colorScheme.secondaryContainer.withValues(
                        alpha: isDark ? .2 : .4,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: .15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.privacy_tip_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSize.paddingXLarge),
              // Sections
              ...List.generate(_sections.length, (index) {
                return _buildSection(
                  context,
                  _sections[index].$1,
                  _sections[index].$2,
                  index,
                );
              }),
              const SizedBox(height: AppSize.paddingXLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: index < _sections.length - 1 ? AppSize.paddingLarge : 0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSize.paddingLarge),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withValues(
            alpha: isDark ? .3 : .8,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: .1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: .03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (index == 0) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingSmall),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSize.paddingSmall),
            Text(
              content,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
