import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';

class SpyRevealDialog extends StatefulWidget {
  const SpyRevealDialog({
    super.key,
    required this.roundIndex,
    required this.spyName,
  });

  final int roundIndex;
  final String spyName;

  @override
  State<SpyRevealDialog> createState() => _SpyRevealDialogState();
}

class _SpyRevealDialogState extends State<SpyRevealDialog> {
  static const _crossfade = Duration(milliseconds: 180);

  bool _revealed = false;

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final spyLineStyle = theme.textTheme.headlineSmall?.copyWith(
      color: AppColors.paper,
      fontWeight: FontWeight.w600,
    );
    final spyLineText = Text(
      l10n.spyRevealLine(widget.spyName),
      style: spyLineStyle,
    );

    return AlertDialog(
      backgroundColor: AppColors.inkRaised,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      title: Text(
        l10n.spyRevealRoundEyebrow(widget.roundIndex),
        style: AppTypography.mono(
          size: 11,
          letterSpacing: 2.2,
          color: AppColors.paperFaint,
        ),
      ),
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _reveal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: _crossfade,
              child: _revealed
                  ? KeyedSubtree(
                      key: const ValueKey('revealed'),
                      child: spyLineText,
                    )
                  : KeyedSubtree(
                      key: const ValueKey('concealed'),
                      child: ImageFiltered(
                        imageFilter:
                            ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                        child: spyLineText,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: _crossfade,
              child: _revealed
                  ? const SizedBox.shrink(key: ValueKey('hint-empty'))
                  : Text(
                      l10n.spyRevealTapHint,
                      key: const ValueKey('hint'),
                      style: AppTypography.mono(
                        size: 11,
                        letterSpacing: 2.2,
                        color: AppColors.paperFaint,
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: _revealed
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: AppColors.lime),
                child: Text(l10n.spyRevealContinue),
              ),
            ]
          : null,
    );
  }
}
