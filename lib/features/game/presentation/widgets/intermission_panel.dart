import 'package:flutter/material.dart';

import '../../../../core/theme/skin_context.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
    final skin = context.skin;
    final l10n = AppLocalizations.of(context);
    final shownTotal = totalRounds > 0 ? totalRounds : lastRoundIndex + 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: skin.inkRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.inkOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.intermissionRoundDone(lastRoundIndex),
            style: skin.monoStyle(
              size: 11,
              letterSpacing: 2.4,
              color: skin.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.intermissionHeadline,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: skin.paper, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.intermissionPrompt(lastRoundIndex + 1, shownTotal),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: skin.paperMuted),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: skin.ink,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: skin.inkOutline),
            ),
            child: Row(
              children: [
                Text(
                  l10n.intermissionReadyLabel,
                  style: skin.monoStyle(
                    size: 10,
                    letterSpacing: 2,
                    color: skin.paperFaint,
                  ),
                ),
                const Spacer(),
                Text(
                  '$readyCount / ${room.players.length}',
                  style: skin.monoStyle(
                    size: 18,
                    weight: FontWeight.w700,
                    color: readyCount == room.players.length
                        ? skin.accent
                        : skin.paper,
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
