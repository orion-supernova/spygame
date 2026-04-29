import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';

class RoomCodeChip extends StatefulWidget {
  const RoomCodeChip({super.key, required this.code});
  final String code;

  @override
  State<RoomCodeChip> createState() => _RoomCodeChipState();
}

class _RoomCodeChipState extends State<RoomCodeChip>
    with SingleTickerProviderStateMixin {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    await Haptics.light();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: _copy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.inkRaised,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _copied
                ? AppColors.lime
                : AppColors.inkOutline,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              l10n.roomCodeLabel,
              style: AppTypography.mono(
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 2.5,
                color: AppColors.paperFaint,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.code,
              style: AppTypography.mono(
                size: 56,
                weight: FontWeight.w700,
                letterSpacing: 14,
                color: AppColors.paper,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _copied
                  ? Row(
                      key: const ValueKey('copied'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 16, color: AppColors.lime),
                        const SizedBox(width: 6),
                        Text(
                          l10n.roomCodeCopied,
                          style: AppTypography.mono(
                            size: 11,
                            weight: FontWeight.w600,
                            letterSpacing: 1.6,
                            color: AppColors.lime,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded,
                            size: 14, color: AppColors.paperFaint),
                        const SizedBox(width: 6),
                        Text(
                          l10n.roomCodeCopyHint,
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
          ],
        ),
      ),
    );
  }
}
