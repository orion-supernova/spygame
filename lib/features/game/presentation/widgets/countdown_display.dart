import 'package:flutter/material.dart';

import '../../../../core/theme/app_skin.dart';
import '../../../../core/theme/skin_context.dart';
import '../countdown_ring.dart';
import 'digital_countdown.dart';
import 'flip_clock_countdown.dart';
import 'pocket_watch_countdown.dart';

/// Hero (large) timer dispatcher — renders the bespoke per-theme countdown
/// based on `context.skin.timerStyle`. Same inputs as [CountdownRing] so the
/// timer header can swap it in transparently.
class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({
    super.key,
    required this.progress,
    required this.seconds,
    required this.totalSeconds,
    required this.label,
  });

  final double progress;
  final int seconds;
  final int totalSeconds;
  final String label;

  @override
  Widget build(BuildContext context) {
    return switch (context.skin.timerStyle) {
      SkinTimerStyle.ring => CountdownRing(
          progress: progress,
          seconds: seconds,
          totalSeconds: totalSeconds,
          label: label,
        ),
      SkinTimerStyle.digital =>
        DigitalCountdown(progress: progress, seconds: seconds, label: label),
      SkinTimerStyle.flipClock =>
        FlipClockCountdown(seconds: seconds, label: label),
      SkinTimerStyle.pocketWatch => PocketWatchCountdown(
          progress: progress,
          seconds: seconds,
          label: label,
        ),
    };
  }
}

/// Compact (collapsed) timer dispatcher — the pinned-chip form of each style.
/// Same inputs as [CountdownChip].
class CountdownCompact extends StatelessWidget {
  const CountdownCompact({
    super.key,
    required this.progress,
    required this.seconds,
    required this.label,
  });

  final double progress;
  final int seconds;
  final String label;

  @override
  Widget build(BuildContext context) {
    return switch (context.skin.timerStyle) {
      SkinTimerStyle.ring =>
        CountdownChip(progress: progress, seconds: seconds, label: label),
      SkinTimerStyle.digital => DigitalCountdown(
          progress: progress,
          seconds: seconds,
          label: label,
          hero: false,
        ),
      SkinTimerStyle.flipClock =>
        FlipClockCountdown(seconds: seconds, label: label, hero: false),
      SkinTimerStyle.pocketWatch => PocketWatchCountdown(
          progress: progress,
          seconds: seconds,
          label: label,
          hero: false,
        ),
    };
  }
}
