import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSize.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Last Updated',
                'December 28, 2025',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                'Introduction',
                'Smart Storage Analyzer ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we handle your information when you use our mobile application.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                'Information We Don\'t Collect',
                'Smart Storage Analyzer is designed with privacy in mind:\n\n'
                    '• We do NOT collect personal information\n'
                    '• We do NOT track your usage\n'
                    '• We do NOT share data with third parties\n'
                    '• We do NOT use analytics or advertising',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                'Local Storage Analysis',
                'Our app analyzes your device storage locally:\n\n'
                    '• All processing happens on your device\n'
                    '• No data leaves your device\n'
                    '• Storage information is not transmitted anywhere\n'
                    '• We only read storage to display statistics',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                'Permissions',
                'We request storage permission to:\n\n'
                    '• Read storage statistics\n'
                    '• Analyze file categories\n'
                    '• Calculate storage usage\n\n'
                    'This permission is used solely for the app\'s core functionality.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                'Data Security',
                'Since we don\'t collect or transmit any data, there\'s no risk of data breaches. All operations are performed locally on your device.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                'Children\'s Privacy',
                'Our app does not collect information from anyone, including children under 13 years of age.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                'Changes to This Policy',
                'We may update this Privacy Policy from time to time. Any changes will be reflected in the app with an updated revision date.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                'Contact Us',
                'If you have any questions about this Privacy Policy, please contact us at:\n\nsupport@smartstorageanalyzer.com',
              ),
              const SizedBox(height: AppSize.paddingXLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppSize.fontXLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSize.paddingSmall),
        Text(
          content,
          style: TextStyle(
            fontSize: AppSize.fontLarge,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}