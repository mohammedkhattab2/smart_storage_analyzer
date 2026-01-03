import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _sections = [
    ('Effective Date', 'December 28, 2025', false),
    (
      '1. Acceptance of Terms',
      'By downloading, installing, or using Smart Storage Analyzer ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
      true,
    ),
    (
      '2. Description of Service',
      'Smart Storage Analyzer is a utility application that:\n\n'
          '• Analyzes device storage usage\n'
          '• Categorizes files by type\n'
          '• Provides storage statistics\n'
          '• Operates entirely offline\n\n'
          'All features work locally on your device without internet connection.',
      true,
    ),
    (
      '3. User Responsibilities',
      'You agree to:\n\n'
          '• Use the App only for lawful purposes\n'
          '• Not reverse engineer or modify the App\n'
          '• Not use the App to harm your device or data\n'
          '• Grant necessary permissions for app functionality',
      true,
    ),
    (
      '4. Privacy & Data',
      'The App:\n\n'
          '• Does NOT collect personal data\n'
          '• Does NOT transmit data to external servers\n'
          '• Does NOT include ads or trackers\n'
          '• Processes all data locally on your device\n\n'
          'Please refer to our Privacy Policy for more details.',
      true,
    ),
    (
      '5. Intellectual Property',
      'Smart Storage Analyzer and all its content, features, and functionality are owned by us and are protected by international copyright, trademark, and other intellectual property laws.',
      true,
    ),
    (
      '6. Disclaimer of Warranties',
      'The App is provided "AS IS" without warranties of any kind. We do not guarantee that:\n\n'
          '• The App will be error-free\n'
          '• Storage calculations will be 100% accurate\n'
          '• The App will meet your specific requirements',
      true,
    ),
    (
      '7. Limitation of Liability',
      'We shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App, including but not limited to data loss or device issues.',
      true,
    ),
    (
      '8. Changes to Terms',
      'We reserve the right to modify these Terms of Service at any time. Changes will be effective immediately upon posting in the App.',
      true,
    ),
    (
      '9. Termination',
      'You may stop using the App at any time by uninstalling it. We reserve the right to terminate or suspend access to the App for violations of these terms.',
      true,
    ),
    (
      '10. Contact Information',
      'For questions about these Terms of Service:\n\n'
          'Email: dimakhattab2017@gmail.com',
      true,
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
          'Terms of Service',
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
                  color: colorScheme.surfaceContainer.withValues(alpha: isDark ? .3 : .6,
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
                      colorScheme.secondaryContainer.withValues(alpha: isDark ? .3 : .5,
                      ),
                      colorScheme.tertiaryContainer.withValues(alpha: isDark ? .2 : .4,
                      ),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary.withValues(alpha: .15,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.description_rounded,
                  size: 48,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSize.paddingXLarge),
              // Sections
              ...List.generate(_sections.length, (index) {
                return _buildSection(
                  context,
                  _sections[index].$1,
                  _sections[index].$2,
                  _sections[index].$3,
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
    bool isNumbered,
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
          color: colorScheme.surfaceContainer.withValues(alpha: isDark ? .3 : .8,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: .1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.secondary.withValues(alpha: .03),
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
                      color: colorScheme.secondary.withValues(alpha: .1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_note_rounded,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingSmall),
                ] else if (isNumbered) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: .5,
                          ),
                          colorScheme.secondaryContainer.withValues(alpha: .5,
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      title.split('.')[0],
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.paddingMedium),
                ],
                Expanded(
                  child: Text(
                    isNumbered && title.contains('.')
                        ? title.substring(title.indexOf('.') + 1).trim()
                        : title,
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
