import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Terms of Service',
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
                'Effective Date',
                'December 28, 2025',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '1. Acceptance of Terms',
                'By downloading, installing, or using Smart Storage Analyzer ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '2. Description of Service',
                'Smart Storage Analyzer is a utility application that:\n\n'
                    '• Analyzes device storage usage\n'
                    '• Categorizes files by type\n'
                    '• Provides storage statistics\n'
                    '• Operates entirely offline\n\n'
                    'All features work locally on your device without internet connection.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '3. User Responsibilities',
                'You agree to:\n\n'
                    '• Use the App only for lawful purposes\n'
                    '• Not reverse engineer or modify the App\n'
                    '• Not use the App to harm your device or data\n'
                    '• Grant necessary permissions for app functionality',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '4. Privacy & Data',
                'The App:\n\n'
                    '• Does NOT collect personal data\n'
                    '• Does NOT transmit data to external servers\n'
                    '• Does NOT include ads or trackers\n'
                    '• Processes all data locally on your device\n\n'
                    'Please refer to our Privacy Policy for more details.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '5. Intellectual Property',
                'Smart Storage Analyzer and all its content, features, and functionality are owned by us and are protected by international copyright, trademark, and other intellectual property laws.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '6. Disclaimer of Warranties',
                'The App is provided "AS IS" without warranties of any kind. We do not guarantee that:\n\n'
                    '• The App will be error-free\n'
                    '• Storage calculations will be 100% accurate\n'
                    '• The App will meet your specific requirements',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '7. Limitation of Liability',
                'We shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App, including but not limited to data loss or device issues.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '8. Changes to Terms',
                'We reserve the right to modify these Terms of Service at any time. Changes will be effective immediately upon posting in the App.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '9. Termination',
                'You may stop using the App at any time by uninstalling it. We reserve the right to terminate or suspend access to the App for violations of these terms.',
              ),
              const SizedBox(height: AppSize.paddingLarge),
              _buildSection(
                '10. Contact Information',
                'For questions about these Terms of Service:\n\n'
                    'Email: support@smartstorageanalyzer.com',
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