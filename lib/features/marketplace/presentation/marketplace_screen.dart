import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show Offering;

import '../../../core/router/app_router.dart';
import '../../../core/theme/skin_backdrop.dart';
import '../../../core/theme/skin_context.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/iap_service.dart';
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
    // RC's locale-formatted prices; cards fall back to the Convex
    // `priceDisplay` until the offering loads (or forever, on web).
    final offering = ref.watch(defaultOfferingProvider).maybeWhen(
          data: (o) => o,
          orElse: () => null,
        );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SkinBackdrop()),
          SafeArea(
            child: bundlesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: context.skin.accent),
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
                              icon: Icon(
                                Icons.close_rounded,
                                color: context.skin.paper,
                              ),
                            ),
                            const Spacer(),
                            const _RestoreOrWebHint(),
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
                                color: context.skin.paper,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              l10n.marketplaceSubtitle,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: context.skin.paperMuted,
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
                        offering: offering,
                      ),
                    if (themed.isNotEmpty)
                      _Section(
                        label: l10n.marketplaceSectionThemed,
                        bundles: themed,
                        owned: owned,
                        offering: offering,
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
    required this.offering,
  });
  final String label;
  final List<Bundle> bundles;
  final Set<String> owned;
  final Offering? offering;

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
                  style: context.skin.monoStyle(
                    size: 11,
                    letterSpacing: 2.4,
                    color: context.skin.paperFaint,
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
                priceOverride: findPackageForSlug(offering, bundle.slug)
                    ?.storeProduct
                    .priceString,
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
      backgroundColor: context.skin.inkRaised,
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
                  color: context.skin.inkOutline,
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
                color: context.skin.paper,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              bundle.tagline,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: context.skin.paperMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.marketplaceComingSoonBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.skin.paperMuted,
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
        Container(width: 28, height: 2, color: context.skin.accent),
        const SizedBox(width: 10),
        Text(
          text,
          style: context.skin.monoStyle(
            size: 11,
            letterSpacing: 2.2,
            color: context.skin.accent,
          ),
        ),
      ],
    );
  }
}

/// Header-row affordance: a "Restore purchases" text button on iOS/Android,
/// or a quiet "Buy on iOS or Android" hint on web (where purchases_flutter
/// is unsupported).
class _RestoreOrWebHint extends ConsumerStatefulWidget {
  const _RestoreOrWebHint();

  @override
  ConsumerState<_RestoreOrWebHint> createState() => _RestoreOrWebHintState();
}

class _RestoreOrWebHintState extends ConsumerState<_RestoreOrWebHint> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (kIsWeb) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          l10n.marketplaceWebPurchaseHint,
          style: context.skin.monoStyle(
            size: 10,
            weight: FontWeight.w500,
            letterSpacing: 1.2,
            color: context.skin.paperFaint,
          ),
        ),
      );
    }
    return TextButton(
      onPressed: _busy ? null : _onTap,
      style: TextButton.styleFrom(
        foregroundColor: context.skin.accent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      child: Text(
        _busy ? l10n.marketplaceRestoring : l10n.marketplaceRestore,
        style: context.skin.monoStyle(
          size: 11,
          weight: FontWeight.w700,
          letterSpacing: 1.4,
          color: _busy ? context.skin.paperFaint : context.skin.accent,
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    await Haptics.light();
    try {
      final restored =
          await ref.read(ownedBundlesProvider.notifier).restore();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            restored.isEmpty
                ? l10n.marketplaceRestoreEmpty
                : l10n.marketplaceRestoreSuccess(restored.length),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.marketplacePurchaseFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          Icon(
            Icons.cloud_off_rounded,
            color: context.skin.danger,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.skin.paperMuted),
          ),
        ],
      ),
    );
  }
}
