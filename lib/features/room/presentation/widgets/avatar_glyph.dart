import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Deterministic, asset-free avatar derived from the player's name. Renders
/// a 4×4 grid of pseudo-random dots with the user's accent hue. Same name
/// always yields the same glyph, so players recognize each other.
class AvatarGlyph extends StatelessWidget {
  const AvatarGlyph({
    super.key,
    required this.seed,
    this.size = 44,
  });

  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hash = _hash(seed);
    final hue = (hash % 360).toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.55, 0.62).toColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.inkSurface,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.inkOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _GlyphPainter(seed: hash, color: color),
      ),
    );
  }

  static int _hash(String s) {
    var h = 2166136261;
    for (final code in s.codeUnits) {
      h = (h ^ code) * 16777619;
      h = h & 0xFFFFFFFF;
    }
    return h;
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.seed, required this.color});
  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const grid = 4;
    final cell = size.width / grid;
    final paint = Paint()..color = color;
    // Mirror left-half over the vertical center for visual cohesion.
    for (var y = 0; y < grid; y++) {
      for (var x = 0; x < (grid / 2).ceil(); x++) {
        if (rng.nextDouble() > 0.55) {
          final r = Rect.fromLTWH(x * cell, y * cell, cell, cell);
          canvas.drawRect(r.deflate(cell * 0.18), paint);
          final mirrorX = (grid - 1 - x) * cell;
          final r2 = Rect.fromLTWH(mirrorX, y * cell, cell, cell);
          canvas.drawRect(r2.deflate(cell * 0.18), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.seed != seed || old.color != color;
}
