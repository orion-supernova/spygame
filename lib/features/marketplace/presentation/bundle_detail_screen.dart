import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
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
                onToggleOwned: () async {
                  Haptics.medium();
                  await ref
                      .read(ownedBundlesProvider.notifier)
                      .setOwned(slug, !owned);
                },
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
    required this.onToggleOwned,
  });

  final BundleDetail detail;
  final bool owned;
  final VoidCallback onToggleOwned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bundle = detail.bundle;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: AppColors.paper),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: bundle.accentColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                bundle.accentColor.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: bundle.accentColor
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: bundle.accentColor,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                bundle.icon,
                                size: 32,
                                color: bundle.accentColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bundle.title,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                      color: AppColors.paper,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bundle.tagline,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: AppColors.paperMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.marketplaceLocationCount(
                                      bundle.locationCount,
                                    ),
                                    style: AppTypography.mono(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      letterSpacing: 1.4,
                                      color: AppColors.paperFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.marketplaceBundleLocationsLabel,
                        style: AppTypography.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 2.2,
                          color: AppColors.paperFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: detail.locations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _LocationTile(
                    location: detail.locations[i],
                    accent: bundle.accentColor,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              if (owned)
                OutlinedButton(
                  onPressed: onToggleOwned,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.paperFaint,
                    side: const BorderSide(color: AppColors.inkOutline),
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(l10n.marketplaceRemoveMock),
                )
              else
                ElevatedButton(
                  onPressed: onToggleOwned,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bundle.accentColor,
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(
                    '${l10n.marketplaceBuy} · ${bundle.priceDisplay}',
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                l10n.marketplaceBuyMockNotice,
                textAlign: TextAlign.center,
                style: AppTypography.mono(
                  size: 10,
                  weight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: AppColors.paperFaint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location, required this.accent});
  final BundleLocation location;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final extra = location.totalRoles - location.sampleRoles.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inkOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final role in location.sampleRoles)
                _RoleChip(text: role),
              if (extra > 0)
                _RoleChip(
                  text: l10n.marketplaceBundleRolesMore(extra),
                  faint: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.text, this.faint = false});
  final String text;
  final bool faint;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inkSurface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.inkOutline),
      ),
      child: Text(
        text,
        style: AppTypography.mono(
          size: 10,
          weight: FontWeight.w600,
          letterSpacing: 0.6,
          color: faint ? AppColors.paperFaint : AppColors.paperMuted,
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
