import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';

class SpyRevealDialog extends StatelessWidget {
  const SpyRevealDialog({
    super.key,
    required this.roundIndex,
    required this.spyName,
  });

  final int roundIndex;
  final String spyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: AppColors.inkRaised,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      title: Text(
        l10n.spyRevealRoundEyebrow(roundIndex),
        style: AppTypography.mono(
          size: 11,
          letterSpacing: 2.2,
          color: AppColors.paperFaint,
        ),
      ),
      content: Text(
        l10n.spyRevealLine(spyName),
        style: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.paper,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.lime),
          child: Text(l10n.spyRevealContinue),
        ),
      ],
    );
  }
}
