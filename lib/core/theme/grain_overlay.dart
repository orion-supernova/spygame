import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A subtle film-grain overlay used on hero surfaces. Deterministic noise
/// rendered with a seeded RNG so it doesn't shimmer between frames.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({
    super.key,
    this.opacity = 0.04,
    this.density = 1800,
    this.seed = 7,
  });

  final double opacity;
  final int density;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GrainPainter(opacity: opacity, density: density, seed: seed),
        size: Size.infinite,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({
    required this.opacity,
    required this.density,
    required this.seed,
  });

  final double opacity;
  final int density;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    for (var i = 0; i < density; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity ||
      oldDelegate.density != density ||
      oldDelegate.seed != seed;
}
