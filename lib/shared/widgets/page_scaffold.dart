import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final scheme = Theme.of(context).colorScheme;
    final horizontal = isMobile ? AppSpacing.lg : AppSpacing.x2;
    final titleStyle = isMobile
        ? Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900);
    final subtitleStyle = isMobile
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.35,
          )
        : Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              isMobile ? AppSpacing.lg : AppSpacing.x2,
              horizontal,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: AnimatedContainer(
                    duration: AppAnimations.component,
                    curve: AppAnimations.curve,
                    padding: EdgeInsets.all(isMobile ? 18 : 22),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: AppShadows.soft(scheme.shadow),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.md,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 780),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: titleStyle),
                              const SizedBox(height: AppSpacing.sm),
                              Text(subtitle, style: subtitleStyle),
                            ],
                          ),
                        ),
                        if (actions.isNotEmpty)
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: actions,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.lg,
              horizontal,
              isMobile ? 112 : AppSpacing.x3,
            ),
            sliver: SliverList.separated(
              itemCount: children.length,
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: AnimatedSwitcher(
                    duration: AppAnimations.micro,
                    child: children[index],
                  ),
                ),
              ),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.xl),
            ),
          ),
        ],
      ),
    );
  }
}
