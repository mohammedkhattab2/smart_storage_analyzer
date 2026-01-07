import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_storage_analyzer/core/constants/app_icons.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/core/constants/app_strings.dart';

class AnalyzeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AnalyzeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: AppSize.paddingSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(
              red: colorScheme.primary.r * 0.9,
              green: colorScheme.primary.g * 0.9,
              blue: colorScheme.primary.b * 0.9,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: .25),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: .08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              borderRadius: BorderRadius.circular(100),
              splashColor: colorScheme.onPrimary.withValues(alpha: .1),
              highlightColor: Colors.transparent,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.analyze,
                      size: 22,
                      color: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: AppSize.paddingSmall + 2),
                    Text(
                      AppStrings.analyzeClean,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.translate(
                      offset: const Offset(3, 0),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: colorScheme.onPrimary.withValues(alpha: .8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
