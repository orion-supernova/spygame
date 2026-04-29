import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../domain/room.dart';

class ConfigPanel extends StatelessWidget {
  const ConfigPanel({
    super.key,
    required this.config,
    required this.editable,
    required this.onChanged,
  });

  final GameConfig config;
  final bool editable;
  final ValueChanged<GameConfig> onChanged;

  @override
  Widget build(BuildContext context) {
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
                'GAME SETTINGS',
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
                  '· host only',
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
            label: 'Spies',
            value: '${config.spyCount}',
            onMinus: editable && config.spyCount > 1
                ? () => onChanged(
                      config.copyWith(spyCount: config.spyCount - 1),
                    )
                : null,
            onPlus: editable && config.spyCount < 3
                ? () => onChanged(
                      config.copyWith(spyCount: config.spyCount + 1),
                    )
                : null,
          ),
          const SizedBox(height: 10),
          _Row(
            label: 'Round minutes',
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
            label: 'Rounds',
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
        ],
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
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: AppColors.paper),
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
    return InkResponse(
      onTap: enabled
          ? () {
              Haptics.selection();
              onTap!.call();
            }
          : null,
      radius: 26,
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
