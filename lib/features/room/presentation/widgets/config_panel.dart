import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../marketplace/data/marketplace_providers.dart';
import '../../domain/room.dart';

class ConfigPanel extends ConsumerWidget {
  const ConfigPanel({
    super.key,
    required this.config,
    required this.editable,
    required this.onChanged,
    required this.onEditLocations,
    required this.onViewLocations,
    required this.activePackSlugs,
    required this.freePackActive,
    required this.enabledLocationCount,
    required this.totalLocationCount,
  });

  final GameConfig config;
  final bool editable;
  final ValueChanged<GameConfig> onChanged;

  /// Host-only callback that opens the editable locations picker sheet.
  final VoidCallback onEditLocations;

  /// Non-host callback that opens the read-only locations sheet.
  final VoidCallback onViewLocations;

  /// Server-derived slugs that have ≥1 enabled location for this room —
  /// the only input the chip strip needs.
  final Set<String> activePackSlugs;
  final bool freePackActive;

  /// Server-derived counts driving the live "X / Y locations" badge.
  final int enabledLocationCount;
  final int totalLocationCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bundlesAsync = ref.watch(bundlesProvider);
    final activeTitles = bundlesAsync.maybeWhen(
      data: (bundles) => bundles
          .where((b) => activePackSlugs.contains(b.slug))
          .map((b) => b.title)
          .toList(),
      orElse: () => const <String>[],
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inkOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.configEyebrow,
                style: AppTypography.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 2,
                  color: AppColors.paperFaint,
                ),
              ),
              const SizedBox(width: 8),
              if (!editable)
                Text(
                  l10n.configHostOnly,
                  style: AppTypography.mono(
                    size: 11,
                    weight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: AppColors.paperFaint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _Row(
            label: l10n.configLabelSpies,
            value: '${config.spyCount}',
            onMinus: editable && config.spyCount > 1
                ? () =>
                      onChanged(config.copyWith(spyCount: config.spyCount - 1))
                : null,
            onPlus: editable && config.spyCount < 3
                ? () =>
                      onChanged(config.copyWith(spyCount: config.spyCount + 1))
                : null,
          ),
          const SizedBox(height: 10),
          _Row(
            label: l10n.configLabelRoundMinutes,
            value: '${config.roundMinutes}',
            onMinus: editable && config.roundMinutes > 1
                ? () => onChanged(
                    config.copyWith(roundMinutes: config.roundMinutes - 1),
                  )
                : null,
            onPlus: editable && config.roundMinutes < 15
                ? () => onChanged(
                    config.copyWith(roundMinutes: config.roundMinutes + 1),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          _Row(
            label: l10n.configLabelRounds,
            value: '${config.roundCount}',
            onMinus: editable && config.roundCount > 1
                ? () => onChanged(
                    config.copyWith(roundCount: config.roundCount - 1),
                  )
                : null,
            onPlus: editable && config.roundCount < 10
                ? () => onChanged(
                    config.copyWith(roundCount: config.roundCount + 1),
                  )
                : null,
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AppColors.inkOutline),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                l10n.configActivePacksLabel,
                style: AppTypography.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 2,
                  color: AppColors.paperFaint,
                ),
              ),
              const SizedBox(width: 8),
              if (!editable)
                Text(
                  l10n.configActivePacksByHost,
                  style: AppTypography.mono(
                    size: 11,
                    weight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: AppColors.paperFaint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (freePackActive) _PackChip(text: l10n.configActivePackFree),
              for (final t in activeTitles) _PackChip(text: t, accent: true),
            ],
          ),
          const SizedBox(height: 14),
          _LocationsRow(
            editable: editable,
            enabled: enabledLocationCount,
            total: totalLocationCount,
            onTap: editable ? onEditLocations : onViewLocations,
          ),
        ],
      ),
    );
  }
}

class _LocationsRow extends StatelessWidget {
  const _LocationsRow({
    required this.editable,
    required this.enabled,
    required this.total,
    required this.onTap,
  });

  final bool editable;
  final int enabled;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = editable
        ? l10n.configEditLocations
        : l10n.configViewLocations;
    final accent = editable ? AppColors.lime : AppColors.paperMuted;
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inkOutline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: accent,
                  ),
                ),
              ),
              Text(
                total == 0 ? '—' : l10n.configLocationsCount(enabled, total),
                style: AppTypography.mono(
                  size: 13,
                  weight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: AppColors.paper,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.paperFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackChip extends StatelessWidget {
  const _PackChip({required this.text, this.accent = false});
  final String text;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.lime : AppColors.paperMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: AppTypography.mono(
          size: 11,
          weight: FontWeight.w600,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.paper),
          ),
        ),
        _StepperButton(icon: Icons.remove, onTap: onMinus),
        SizedBox(
          width: 56,
          child: Center(
            child: Text(
              value,
              style: AppTypography.mono(
                size: 22,
                weight: FontWeight.w700,
                color: AppColors.paper,
              ),
            ),
          ),
        ),
        _StepperButton(icon: Icons.add, onTap: onPlus),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled
          ? () {
              Haptics.selection();
              onTap!.call();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.inkSurface : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.inkOutline : AppColors.inkOutline,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.paper : AppColors.paperFaint,
        ),
      ),
    );
  }
}
