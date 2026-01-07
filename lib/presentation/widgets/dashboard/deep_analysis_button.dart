import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_storage_analyzer/core/constants/app_size.dart';
import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';
import 'package:smart_storage_analyzer/presentation/cubits/pro_access/pro_access_cubit.dart';
import 'package:smart_storage_analyzer/presentation/cubits/pro_access/pro_access_state.dart';
import 'package:smart_storage_analyzer/presentation/viewmodels/pro_access_viewmodel.dart';
import 'package:smart_storage_analyzer/presentation/widgets/common/pro_badge.dart';

/// Example of a Pro feature button with soft gating
class DeepAnalysisButton extends StatelessWidget {
  final VoidCallback? onFreeTap;

  const DeepAnalysisButton({super.key, this.onFreeTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ProAccessCubit, ProAccessState>(
      builder: (context, proState) {
        final viewModel = context.read<ProAccessViewModel>();

        return FutureBuilder<bool>(
          future: viewModel.hasFeature(ProFeature.deepAnalysis.name),
          builder: (context, snapshot) {
            final hasFeature = snapshot.data ?? false;

            return Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasFeature
                      ? [colorScheme.primary, colorScheme.secondary]
                      : [
                          colorScheme.surfaceContainerHighest,
                          colorScheme.surfaceContainer,
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: hasFeature
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: .3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleTap(context, hasFeature),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.paddingLarge,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          color: hasFeature
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSize.paddingMedium),
                        Text(
                          'Deep Analysis',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: hasFeature
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: AppSize.paddingSmall),
                        if (!hasFeature) const ProBadge(size: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context, bool hasFeature) async {
    if (hasFeature) {
      // Execute Pro feature
      _runDeepAnalysis(context);
    } else {
      // Show Pro feature dialog
      final featureGate = context.read<ProAccessViewModel>().featureGate;
      await featureGate.showProFeatureDialog(context, ProFeature.deepAnalysis);

      // Optionally run free version
      onFreeTap?.call();
    }
  }

  void _runDeepAnalysis(BuildContext context) {
    // This would execute the actual deep analysis
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deep Analysis would run here (Pro feature)'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Example of inline Pro feature indicator
class ProFeatureIndicator extends StatelessWidget {
  final ProFeature feature;
  final Widget child;

  const ProFeatureIndicator({
    super.key,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<ProAccessViewModel>().hasFeature(feature.name),
      builder: (context, snapshot) {
        final hasFeature = snapshot.data ?? false;

        if (hasFeature) {
          return child;
        }

        return Stack(
          children: [
            Opacity(opacity: 0.7, child: child),
            const Positioned(top: 4, right: 4, child: ProIndicator(size: 12)),
          ],
        );
      },
    );
  }
}
