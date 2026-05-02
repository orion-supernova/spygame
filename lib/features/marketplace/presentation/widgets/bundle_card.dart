import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/bundle.dart';

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
    final placeholder = bundle.isPlaceholder;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.inkRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: placeholder
                  ? AppColors.inkOutline
                  : bundle.accentColor.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bundle.accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: bundle.accentColor.withValues(alpha: 0.45),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  bundle.icon,
                  size: 28,
                  color: bundle.accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.paper,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bundle.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.paperMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (placeholder)
                          _Pill(
                            text: l10n.marketplaceComingSoon,
                            color: AppColors.paperFaint,
                          )
                        else if (owned)
                          _Pill(
                            text: l10n.marketplaceOwnedBadge,
                            color: AppColors.lime,
                          )
                        else
                          _Pill(
                            text: bundle.priceDisplay,
                            color: bundle.accentColor,
                          ),
                        const SizedBox(width: 8),
                        if (!placeholder)
                          Text(
                            l10n.marketplaceLocationCount(bundle.locationCount),
                            style: AppTypography.mono(
                              size: 10,
                              weight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppColors.paperFaint,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.paperFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: AppTypography.mono(
          size: 10,
          weight: FontWeight.w700,
          letterSpacing: 1.6,
          color: color,
        ),
      ),
    );
  }
}
