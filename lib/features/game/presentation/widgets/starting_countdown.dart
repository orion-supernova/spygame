import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/convex/server_time_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Big "Starting in 3..." number, server-time driven so every device
/// counts down to the same instant. Uses the shared serverTimeOffset so
/// that the actual round-start moment lines up across players.
class StartingCountdown extends ConsumerStatefulWidget {
  const StartingCountdown({
    super.key,
    required this.startsAtServerMs,
    required this.snapshotServerNowMs,
    required this.snapshotReceivedAtLocalMs,
    required this.roundIndex,
  });

  final int startsAtServerMs;
  final int snapshotServerNowMs;
  final int snapshotReceivedAtLocalMs;
  final int roundIndex;

  @override
  ConsumerState<StartingCountdown> createState() => _StartingCountdownState();
}

class _StartingCountdownState extends ConsumerState<StartingCountdown>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  int _lastSecond = -1;

  @override
  void initState() {
    super.initState();
    // Re-sample server time when the tiny countdown appears, but render from
    // the room snapshot immediately so a stale global offset cannot show 6.
    // ignore: discarded_futures
    Future.microtask(
      () => ref.read(serverTimeOffsetProvider.notifier).refresh(),
    );
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = ref.watch(serverTimeOffsetProvider);
    final localNow = DateTime.now().millisecondsSinceEpoch;
    final offsetServerNow = localNow + offset;
    final snapshotElapsedMs = (localNow - widget.snapshotReceivedAtLocalMs)
        .clamp(0, 1 << 31);
    final snapshotServerNow = widget.snapshotServerNowMs + snapshotElapsedMs;
    final nowServer = offsetServerNow > snapshotServerNow
        ? offsetServerNow
        : snapshotServerNow;
    final remainingMs = widget.startsAtServerMs - nowServer;
    final seconds = remainingMs <= 0
        ? 0
        : (((remainingMs - 1) ~/ 1000) + 1).clamp(0, 3);

    if (seconds != _lastSecond && seconds > 0 && seconds <= 3) {
      _lastSecond = seconds;
      // Tick haptic on each second.
      // ignore: discarded_futures
      Haptics.selection();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lime, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            l10n.gameRoundStartsIn(widget.roundIndex),
            style: AppTypography.mono(
              size: 11,
              weight: FontWeight.w600,
              letterSpacing: 2.4,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              seconds == 0 ? l10n.gameStartingGo : '$seconds',
              key: ValueKey<int>(seconds),
              style: AppTypography.mono(
                size: 96,
                weight: FontWeight.w700,
                color: AppColors.lime,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.gameStartingGetReady,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.paperMuted,
            ),
          ),
        ],
      ),
    );
  }
}
