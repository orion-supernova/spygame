import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/room.dart';
import 'avatar_glyph.dart';

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.player,
    required this.isSelf,
  });

  final Player player;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: player.isReady
              ? AppColors.lime.withValues(alpha: 0.6)
              : AppColors.inkOutline,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          AvatarGlyph(seed: player.displayName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.paper),
                      ),
                    ),
                    if (player.isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lime.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HOST',
                          style: AppTypography.mono(
                            size: 9,
                            weight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: AppColors.lime,
                          ),
                        ),
                      ),
                    ],
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Text(
                        'YOU',
                        style: AppTypography.mono(
                          size: 9,
                          weight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: AppColors.paperFaint,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  player.isReady ? 'Ready' : 'Standing by…',
                  style: AppTypography.mono(
                    size: 11,
                    weight: FontWeight.w500,
                    letterSpacing: 0.8,
                    color: player.isReady
                        ? AppColors.lime
                        : AppColors.paperFaint,
                  ),
                ),
              ],
            ),
          ),
          _ReadyDot(ready: player.isReady),
        ],
      ),
    );
  }
}

class _ReadyDot extends StatelessWidget {
  const _ReadyDot({required this.ready});
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ready ? AppColors.lime : Colors.transparent,
        border: Border.all(
          color: ready ? AppColors.lime : AppColors.inkOutline,
          width: 1.6,
        ),
      ),
      child: ready
          ? const Icon(Icons.check, size: 16, color: AppColors.ink)
          : null,
    );
  }
}
