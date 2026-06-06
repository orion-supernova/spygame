import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/iap_service.dart';
import '../data/marketplace_providers.dart';
import '../domain/bundle.dart';

class BundleDetailScreen extends ConsumerWidget {
  const BundleDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(bundleDetailProvider(slug));
    final owned = ref.watch(ownedBundlesProvider).contains(slug);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.ink)),
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            child: detailAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              ),
              error: (e, _) => _ErrorView(message: e.toString()),
              data: (detail) => _DetailView(
                detail: detail,
                owned: owned,
                slug: slug,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.detail,
    required this.owned,
    required this.slug,
  });

  final BundleDetail detail;
  final bool owned;
  final String slug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bundle = detail.bundle;

    final categoryLabel = bundle.category == BundleCategory.city
        ? l10n.marketplaceCategoryCity
        : l10n.marketplaceCategoryTheme;

    // Roles per location is uniform (11) by game design; show that figure
    // in the friendly meta line rather than computing the average across
    // locations.
    const rolesPerLocation = 11;

    return Column(
      children: [
        Padding(
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
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Eyebrow(text: categoryLabel),
                      const SizedBox(height: 18),
                      Text(
                        bundle.title,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 56,
                          height: 0.98,
                          color: AppColors.paper,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        bundle.tagline,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.paperMuted,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.marketplaceLocationsAndRoles(
                          bundle.locationCount,
                          rolesPerLocation,
                        ),
                        style: AppTypography.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 1.6,
                          color: AppColors.paperFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(28, 6, 28, 14),
                sliver: SliverToBoxAdapter(
                  child: _Eyebrow(text: l10n.marketplaceBundleContentsLabel),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                sliver: SliverList.separated(
                  itemCount: detail.locations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _LocationCard(location: detail.locations[i]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 18),
          child: owned
              ? const _OwnedBlock()
              : _UnlockBlock(slug: slug, fallbackPrice: bundle.priceDisplay),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});
  final BundleLocation location;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final extra = location.totalRoles - location.sampleRoles.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inkOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.name,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.paper,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final role in location.sampleRoles) _RoleChip(text: role),
              if (extra > 0)
                _RoleChip(
                  text: l10n.marketplaceBundleRolesMore(extra),
                  muted: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.text, this.muted = false});
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    // `muted: true` is the "+ N more" affordance — same shape as a regular
    // role chip, recolored with the lime accent so it pops as a hint that
    // more roles are hidden. Previously it ghosted into the background.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.lime.withValues(alpha: 0.10)
            : AppColors.ink.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: muted
              ? AppColors.lime.withValues(alpha: 0.55)
              : AppColors.inkOutline,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.mono(
          size: 10,
          weight: FontWeight.w700,
          letterSpacing: muted ? 1.4 : 0.8,
          color: muted ? AppColors.lime : AppColors.paperMuted,
        ),
      ),
    );
  }
}

/// Buy CTA. Resolves the matching RevenueCat [Package] from the active
/// offering by slug; the price label uses RC's locale-formatted
/// [StoreProduct.priceString] when available and falls back to the
/// Convex `priceUsd` if the offering hasn't loaded yet (or never will,
/// e.g. on web).
class _UnlockBlock extends ConsumerStatefulWidget {
  const _UnlockBlock({required this.slug, required this.fallbackPrice});
  final String slug;
  final String fallbackPrice;

  @override
  ConsumerState<_UnlockBlock> createState() => _UnlockBlockState();
}

class _UnlockBlockState extends ConsumerState<_UnlockBlock> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offeringAsync = ref.watch(defaultOfferingProvider);
    final package = offeringAsync.maybeWhen(
      data: (offering) => findPackageForSlug(offering, widget.slug),
      orElse: () => null,
    );

    final price = package?.storeProduct.priceString ?? widget.fallbackPrice;
    final canBuy = !kIsWeb && !_busy && package != null;

    final label = _busy
        ? l10n.marketplaceUnlocking
        : '${l10n.marketplaceUnlock} · $price';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canBuy ? () => _onTap(package) : null,
            child: Text(label),
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 8),
          Text(
            l10n.marketplaceWebPurchaseHint,
            textAlign: TextAlign.center,
            style: AppTypography.mono(
              size: 10,
              weight: FontWeight.w500,
              letterSpacing: 1.2,
              color: AppColors.paperFaint,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _onTap(Package package) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    await Haptics.medium();
    try {
      await ref
          .read(ownedBundlesProvider.notifier)
          .purchasePackage(package);
      // Success state is rendered via ownedBundlesProvider (the parent
      // detail screen rebuilds with _OwnedBlock).
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

class _OwnedBlock extends StatelessWidget {
  const _OwnedBlock();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: AppColors.lime, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.marketplaceOwnedBanner,
              style: AppTypography.mono(
                size: 12,
                weight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.lime,
              ),
            ),
          ),
        ],
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
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.signalRed, size: 36),
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
