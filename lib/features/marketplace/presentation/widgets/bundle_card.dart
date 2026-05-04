import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/bundle.dart';

/// Soft, rounded "invitation" card matching the welcome and how-to-play
/// language: ink-raised surface, paper title, italic muted tagline,
/// single lime-tick eyebrow. No file IDs, classification badges, status
/// stripes, or per-bundle accent colors — those read as a generic
/// mobile-game storefront. Owned cards earn a lime border and a small
/// check; placeholders dim to paperFaint.
class BundleCard extends StatelessWidget {
  const BundleCard({
    super.key,
    required this.bundle,
    required this.owned,
    required this.onTap,
  });

  final Bundle bundle;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isPlaceholder = bundle.isPlaceholder;

    final String eyebrowText;
    final Color eyebrowColor;
    if (isPlaceholder) {
      eyebrowText = l10n.marketplaceComingSoon;
      eyebrowColor = AppColors.paperFaint;
    } else if (owned) {
      eyebrowText = l10n.marketplaceOwnedBadge;
      eyebrowColor = AppColors.lime;
    } else {
      eyebrowText = bundle.category == BundleCategory.city
          ? l10n.marketplaceCategoryCity
          : l10n.marketplaceCategoryTheme;
      eyebrowColor = AppColors.lime;
    }

    final Color borderColor;
    final double borderWidth;
    if (owned) {
      borderColor = AppColors.lime.withValues(alpha: 0.7);
      borderWidth = 1.5;
    } else if (isPlaceholder) {
      borderColor = AppColors.inkOutline.withValues(alpha: 0.5);
      borderWidth = 1;
    } else {
      borderColor = AppColors.inkOutline;
      borderWidth = 1;
    }

    final titleColor = isPlaceholder ? AppColors.paperMuted : AppColors.paper;
    final radius = BorderRadius.circular(22);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: AppColors.lime.withValues(alpha: 0.06),
        highlightColor: AppColors.lime.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.inkRaised,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(text: eyebrowText, color: eyebrowColor),
                const SizedBox(height: 16),
                Text(
                  bundle.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bundle.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPlaceholder
                        ? AppColors.paperFaint
                        : AppColors.paperMuted,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                if (!isPlaceholder) ...[
                  const SizedBox(height: 18),
                  _Footer(
                    locationCount: bundle.locationCount,
                    priceDisplay: bundle.priceDisplay,
                    owned: owned,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 22, height: 2, color: color),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppTypography.mono(
            size: 11,
            weight: FontWeight.w600,
            letterSpacing: 2.2,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.locationCount,
    required this.priceDisplay,
    required this.owned,
  });

  final int locationCount;
  final String priceDisplay;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.marketplaceLocationCount(locationCount),
            style: AppTypography.mono(
              size: 11,
              weight: FontWeight.w500,
              letterSpacing: 1.6,
              color: AppColors.paperFaint,
            ),
          ),
        ),
        if (owned)
          const Icon(
            Icons.check_rounded,
            size: 18,
            color: AppColors.lime,
          )
        else
          Text(
            priceDisplay,
            style: AppTypography.mono(
              size: 14,
              weight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.paper,
            ),
          ),
      ],
    );
  }
}
