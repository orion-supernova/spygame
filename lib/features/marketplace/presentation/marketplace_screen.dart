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
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go(AppRoute.welcome),
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.paper,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.marketplaceTitle,
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: AppColors.paper,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.marketplaceSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
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
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  label,
                  style: AppTypography.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 2.2,
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.inkRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(bundle.icon, size: 28, color: bundle.accentColor),
                const SizedBox(width: 12),
                Text(
                  bundle.title,
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        color: AppColors.paper,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.marketplaceComingSoon,
              style: AppTypography.mono(
                size: 11,
                weight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.lime,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.marketplaceComingSoonBody,
              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                    color: AppColors.paperMuted,
                  ),
            ),
          ],
        ),
      ),
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
