import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_skin.dart';
import '../../../core/theme/skin_context.dart';

Color countdownAccent(AppSkin skin, int seconds) {
  if (seconds <= 10) return skin.danger;
  if (seconds <= 30) return skin.secondary;
  return skin.accent;
}

String formatCountdown(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.progress,
    required this.seconds,
    required this.totalSeconds,
    required this.label,
  });

  final double progress; // 0..1, remaining/total
  final int seconds;
  final int totalSeconds;
  final String label;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final accent = countdownAccent(skin, seconds);
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          // Constrain content to a safe horizontal chord inside the ring so
          // digits never collide with the stroke on narrow devices.
          final innerWidth = diameter * 0.72;
          final spacing = (diameter * 0.05).clamp(6.0, 14.0).toDouble();
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: RingPainter(
                  progress: progress,
                  color: accent,
                  trackColor: skin.inkOutline,
                ),
                size: Size.infinite,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: innerWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: skin.monoStyle(
                          size: 11,
                          letterSpacing: 2.4,
                          color: skin.paperFaint,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  SizedBox(
                    width: innerWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatCountdown(seconds),
                        maxLines: 1,
                        softWrap: false,
                        style: skin.digitStyle(
                          size: 80,
                          letterSpacing: -2,
                          color: accent,
                        ).copyWith(height: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact horizontal pill: small ring + digits + label.
/// Used as the pinned-collapsed state of the in-game header.
class CountdownChip extends StatelessWidget {
  const CountdownChip({
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
    final skin = context.skin;
    final accent = countdownAccent(skin, seconds);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: skin.inkRaised,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: skin.inkOutline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(
              painter: RingPainter(
                progress: progress,
                color: accent,
                trackColor: skin.inkOutline,
                strokeWidth: 4,
                trackStrokeWidth: 3,
                inset: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCountdown(seconds),
            style: skin.digitStyle(
              size: 22,
              letterSpacing: -0.5,
              color: accent,
            ).copyWith(height: 1),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: skin.monoStyle(
              size: 10,
              letterSpacing: 2,
              color: skin.paperFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 10,
    this.trackStrokeWidth = 8,
    this.inset = 12,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double trackStrokeWidth;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - inset;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = trackStrokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = color;
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.trackStrokeWidth != trackStrokeWidth ||
      old.inset != inset;
}
