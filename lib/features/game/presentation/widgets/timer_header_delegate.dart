import 'package:flutter/material.dart';

import '../../../../core/theme/skin_context.dart';
import 'countdown_display.dart';

/// Pinned header that morphs from a full hero timer to a compact chip as the
/// user scrolls. The actual timer form (ring / digital / flip-clock /
/// pocket-watch) is chosen per theme by [CountdownDisplay]/[CountdownCompact].
class TimerHeaderDelegate extends SliverPersistentHeaderDelegate {
  TimerHeaderDelegate({
    required this.progress,
    required this.seconds,
    required this.totalSeconds,
    required this.label,
    required this.maxExtent,
    this.minExtent = 64,
  });

  final double progress;
  final int seconds;
  final int totalSeconds;
  final String label;

  @override
  final double maxExtent;
  @override
  final double minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final t = (shrinkOffset / range).clamp(0.0, 1.0).toDouble();

    final heroOpacity = (1 - (t / 0.35)).clamp(0.0, 1.0);
    final chipOpacity = ((t - 0.35) / 0.35).clamp(0.0, 1.0);

    return ClipRect(
      child: Container(
        // Solid, skin-aware background so the chip reads over scrolling content.
        color: context.skin.ink,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: heroOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: CountdownDisplay(
                        progress: progress,
                        seconds: seconds,
                        totalSeconds: totalSeconds,
                        label: label,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: IgnorePointer(
                child: Opacity(
                  opacity: chipOpacity,
                  child: Center(
                    child: CountdownCompact(
                      progress: progress,
                      seconds: seconds,
                      label: label,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant TimerHeaderDelegate old) {
    return old.progress != progress ||
        old.seconds != seconds ||
        old.totalSeconds != totalSeconds ||
        old.label != label ||
        old.maxExtent != maxExtent ||
        old.minExtent != minExtent;
  }
}
