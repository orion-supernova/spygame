import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/marketplace_providers.dart';
import '../domain/bundle.dart';
import 'widgets/bundle_card.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bundlesAsync = ref.watch(bundlesProvider);
    final placeholders = ref.watch(placeholderBundlesProvider);
    final owned = ref.watch(ownedBundlesProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.ink)),
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            child: bundlesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              ),
              error: (e, _) => _ErrorView(message: e.toString()),
              data: (bundles) {
                final cities = [
                  ...bundles.where((b) => b.category == BundleCategory.city),
                  ...placeholders
                      .where((b) => b.category == BundleCategory.city),
                ];
                final themed = [
                  ...bundles.where((b) => b.category == BundleCategory.theme),
                  ...placeholders
                      .where((b) => b.category == BundleCategory.theme),
                ];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.paper,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Eyebrow(text: l10n.marketplaceEyebrow),
                            const SizedBox(height: 18),
                            Text(
                              l10n.marketplaceTitle,
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 60,
                                height: 0.95,
                                color: AppColors.paper,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              l10n.marketplaceSubtitle,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.paperMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (cities.isNotEmpty)
                      _Section(
                        label: l10n.marketplaceSectionPopularCities,
                        bundles: cities,
                        owned: owned,
                      ),
                    if (themed.isNotEmpty)
                      _Section(
                        label: l10n.marketplaceSectionThemed,
                        bundles: themed,
                        owned: owned,
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.bundles,
    required this.owned,
  });
  final String label;
  final List<Bundle> bundles;
  final Set<String> owned;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
                child: Text(
                  label,
                  style: AppTypography.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 2.4,
                    color: AppColors.paperFaint,
                  ),
                ),
              );
            }
            final bundle = bundles[i - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BundleCard(
                bundle: bundle,
                owned: owned.contains(bundle.slug),
                onTap: () => _onTap(context, bundle),
              ),
            );
          },
          childCount: bundles.length + 1,
        ),
      ),
    );
  }

  void _onTap(BuildContext context, Bundle bundle) {
    if (bundle.isPlaceholder) {
      _showComingSoon(context, bundle);
      return;
    }
    context.push(AppRoute.bundleDetailFor(bundle.slug));
  }

  void _showComingSoon(BuildContext context, Bundle bundle) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.inkRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _Eyebrow(text: l10n.marketplaceComingSoon),
            const SizedBox(height: 14),
            Text(
              bundle.title,
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.paper,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              bundle.tagline,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.paperMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.marketplaceComingSoonBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.paperMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 28, height: 2, color: AppColors.lime),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppTypography.mono(
            size: 11,
            weight: FontWeight.w600,
            letterSpacing: 2.2,
            color: AppColors.lime,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.signalRed,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.paperMuted),
          ),
        ],
      ),
    );
  }
}
