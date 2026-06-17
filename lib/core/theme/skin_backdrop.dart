import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_skin.dart';
import 'skin_context.dart';

/// Full-screen, skin-aware backdrop painted behind every routed page.
/// Mounted once in `MaterialApp.builder`; individual screens render on
/// transparent scaffolds on top of it.
///
/// Each [SkinTexture] gets a distinct treatment so the active theme is felt
/// even in empty space: film grain (noir), scanlines + glow (cyberpunk),
/// candlelit vignette (victorian), kraft-paper fibre (wild west).
class SkinBackdrop extends StatelessWidget {
  const SkinBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return IgnorePointer(
      child: CustomPaint(
        painter: _BackdropPainter(skin),
        size: Size.infinite,
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.skin);

  final AppSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill so the backdrop is opaque even over a transparent scaffold.
    canvas.drawRect(Offset.zero & size, Paint()..color = skin.ink);

    switch (skin.texture) {
      case SkinTexture.grain:
        _paintGrain(canvas, size, color: Colors.white, opacity: 0.04);
      case SkinTexture.scanlines:
        _paintScanlines(canvas, size);
      case SkinTexture.parchment:
        _paintParchment(canvas, size);
      case SkinTexture.kraft:
        _paintKraft(canvas, size);
      case SkinTexture.fog:
        _paintFog(canvas, size);
      case SkinTexture.grid:
        _paintGrid(canvas, size);
    }
  }

  void _paintGrain(
    Canvas canvas,
    Size size, {
    required Color color,
    required double opacity,
    int density = 1800,
    int seed = 7,
  }) {
    final rng = math.Random(seed);
    final paint = Paint()..color = color.withValues(alpha: opacity);
    for (var i = 0; i < density; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.4, paint);
    }
  }

  void _paintScanlines(Canvas canvas, Size size) {
    // Cyan glow blooming from the top, then horizontal CRT scanlines.
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.1),
        radius: 1.3,
        colors: [
          skin.accent.withValues(alpha: 0.12),
          skin.secondary.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final line = Paint()..color = Colors.black.withValues(alpha: 0.18);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
    _paintGrain(canvas, size, color: skin.accent, opacity: 0.03, density: 600);
  }

  void _paintParchment(Canvas canvas, Size size) {
    // Warm candlelight pooling centre-top, darkening to the edges.
    final pool = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.0,
        colors: [
          skin.accent.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, pool);

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 1.1,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    _paintGrain(canvas, size, color: skin.paper, opacity: 0.025, density: 1400);
  }

  void _paintKraft(Canvas canvas, Size size) {
    // Paper fibre: faint horizontal streaks plus speckle in the paper tone.
    final streak = Paint()..color = skin.paper.withValues(alpha: 0.015);
    final rng = math.Random(13);
    for (var i = 0; i < 120; i++) {
      final y = rng.nextDouble() * size.height;
      final x = rng.nextDouble() * size.width;
      final w = 20 + rng.nextDouble() * 90;
      canvas.drawRect(Rect.fromLTWH(x, y, w, 0.6), streak);
    }
    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 1.2,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.28),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
    _paintGrain(canvas, size, color: skin.paper, opacity: 0.03, density: 1600);
  }

  void _paintFog(Canvas canvas, Size size) {
    // Cool gaslit London: drifting haze + a faint light shaft, cool vignette.
    // Static (no animation) so it stays cheap and reduced-motion safe.
    final rng = math.Random(29);
    for (var i = 0; i < 3; i++) {
      final cx = (0.2 + 0.3 * i) * size.width;
      final cy = (0.25 + rng.nextDouble() * 0.4) * size.height;
      final r = size.shortestSide * (0.5 + rng.nextDouble() * 0.4);
      final haze = Paint()
        ..shader = RadialGradient(
          colors: [
            (i.isEven ? skin.paper : skin.accent).withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawRect(Offset.zero & size, haze);
    }

    // A pale shaft of gaslight from the top.
    final shaft = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x14C9A24B), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shaft);

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 1.1,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.4),
        ],
        stops: const [0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    _paintGrain(canvas, size, color: skin.paper, opacity: 0.02, density: 1300);
  }

  void _paintGrid(Canvas canvas, Size size) {
    // Cyberpunk: neon perspective grid receding to a vanishing point, plus a
    // top glow and CRT scanlines.
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.0),
        radius: 1.3,
        colors: [
          skin.accent.withValues(alpha: 0.14),
          skin.secondary.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final horizon = size.height * 0.52;
    final vanishX = size.width / 2;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = skin.accent.withValues(alpha: 0.18);

    // Converging vertical lines below the horizon.
    const cols = 12;
    for (var i = 0; i <= cols; i++) {
      final x = size.width * i / cols;
      canvas.drawLine(Offset(vanishX, horizon), Offset(x, size.height), line);
    }
    // Horizontal lines with perspective spacing (denser near the horizon).
    for (var i = 1; i <= 10; i++) {
      final t = i / 10;
      final y = horizon + (size.height - horizon) * (t * t);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        line..color = skin.accent.withValues(alpha: 0.10 + 0.12 * t),
      );
    }

    // CRT scanlines over the whole frame.
    final scan = Paint()..color = Colors.black.withValues(alpha: 0.16);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.skin.id != skin.id;
}
