import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../room/domain/room.dart';
import '../../../room/presentation/widgets/player_tile.dart';
import '../../../room/presentation/widgets/ready_button.dart';

/// Shown between rounds while the table debriefs. Players re-tap Ready;
/// the moment everyone is ready the server flips into `starting` and a
/// 3-second countdown takes over.
class IntermissionPanel extends StatelessWidget {
  const IntermissionPanel({
    super.key,
    required this.room,
    required this.myToken,
    required this.lastRoundIndex,
    required this.totalRounds,
    required this.onToggleReady,
  });

  final Room room;
  final String myToken;
  final int lastRoundIndex;
  final int totalRounds;
  final VoidCallback onToggleReady;

  @override
  Widget build(BuildContext context) {
    final me = room.playerFor(myToken);
    final readyCount = room.players.where((p) => p.isReady).length;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inkOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ROUND $lastRoundIndex DONE',
            style: AppTypography.mono(
              size: 11,
              weight: FontWeight.w600,
              letterSpacing: 2.4,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Take a beat. Talk it out.',
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: AppColors.paper, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap ready when you\'re set for round ${lastRoundIndex + 1}'
            '${totalRounds > 0 ? ' of $totalRounds' : ''}.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.paperMuted),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inkOutline),
            ),
            child: Row(
              children: [
                Text(
                  'READY',
                  style: AppTypography.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    letterSpacing: 2,
                    color: AppColors.paperFaint,
                  ),
                ),
                const Spacer(),
                Text(
                  '$readyCount / ${room.players.length}',
                  style: AppTypography.mono(
                    size: 18,
                    weight: FontWeight.w700,
                    color: readyCount == room.players.length
                        ? AppColors.lime
                        : AppColors.paper,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...room.players.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlayerTile(
                player: p,
                isSelf: p.clientToken == myToken,
              ),
            ),
          ),
          if (me != null) ...[
            const SizedBox(height: 6),
            ReadyButton(ready: me.isReady, onToggle: onToggleReady),
          ],
        ],
      ),
    );
  }
}
