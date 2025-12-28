import 'package:flutter/material.dart';
import 'package:smart_storage_analyzer/core/constants/app_colors.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'About',
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
            children: [
              const SizedBox(height: AppSize.paddingXLarge),
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSize.radiusXLarge),
                ),
                child: const Icon(
                  Icons.storage,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSize.paddingLarge),
              // App Name
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: AppSize.fontXXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSize.paddingSmall),
              // Version
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: AppSize.fontLarge,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSize.paddingXLarge),
              // Description
              Container(
                padding: const EdgeInsets.all(AppSize.paddingLarge),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSize.radiusLarge),
                ),
                child: Column(
                  children: [
                    Text(
                      'Smart Storage Analyzer helps you understand and manage your device storage efficiently.',
                      style: TextStyle(
                        fontSize: AppSize.fontLarge,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSize.paddingLarge),
                    _buildFeature(Icons.offline_bolt, 'Works 100% Offline'),
                    const SizedBox(height: AppSize.paddingMedium),
                    _buildFeature(Icons.privacy_tip, 'Privacy-First Design'),
                    const SizedBox(height: AppSize.paddingMedium),
                    _buildFeature(Icons.block, 'No Ads, No Tracking'),
                    const SizedBox(height: AppSize.paddingMedium),
                    _buildFeature(Icons.speed, 'Fast & Lightweight'),
                  ],
                ),
              ),
              const SizedBox(height: AppSize.paddingXLarge),
              // Developer Info
              _buildInfoSection('Developer', 'Smart Storage Team'),
              const SizedBox(height: AppSize.paddingMedium),
              _buildInfoSection('Contact', 'support@smartstorageanalyzer.com'),
              const SizedBox(height: AppSize.paddingMedium),
              _buildInfoSection('Website', 'www.smartstorageanalyzer.com'),
              const SizedBox(height: AppSize.paddingXLarge * 2),
              // Copyright
              Text(
                '© 2025 Smart Storage Analyzer',
                style: TextStyle(
                  fontSize: AppSize.fontSmall,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSize.paddingSmall),
              Text(
                'All rights reserved',
                style: TextStyle(
                  fontSize: AppSize.fontSmall,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSize.paddingXLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSize.iconSmall,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSize.paddingSmall),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppSize.fontMedium,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppSize.fontMedium,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSize.fontMedium,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}