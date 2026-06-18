import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_skin.dart';
import '../../../../core/theme/skin_context.dart';
import '../countdown_ring.dart';

/// Victorian timer: an ornate brass pocket-watch. A sweeping hand and a
/// shrinking remaining-arc encode the time geometrically (shape, not colour
/// alone); the MM:SS sits in an engraved sub-dial. The hand is the core
/// readout so it stays smooth even under reduced motion.
class PocketWatchCountdown extends StatelessWidget {
  const PocketWatchCountdown({
    super.key,
    required this.progress,
    required this.seconds,
    required this.label,
    this.hero = true,
  });

  final double progress;
  final int seconds;
  final String label;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final accent = countdownAccent(skin, seconds);

    if (!hero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: skin.inkRaised,
          borderRadius: BorderRadius.circular(skin.cardRadius),
          border: Border.all(color: skin.inkOutline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CustomPaint(
                painter: _PocketWatchPainter(
                  progress: progress,
                  hand: accent,
                  skin: skin,
                  showNumerals: false,
                  showCenter: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatCountdown(seconds),
              style: skin.digitStyle(size: 22, color: accent),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: skin.monoStyle(size: 10, letterSpacing: 2, color: skin.paperFaint),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _PocketWatchPainter(
          progress: progress,
          hand: accent,
          skin: skin,
          showNumerals: skin.ornament,
          showCenter: true,
          centerText: formatCountdown(seconds),
          label: label,
        ),
      ),
    );
  }
}

const _roman = [
  'XII', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI',
];

class _PocketWatchPainter extends CustomPainter {
  _PocketWatchPainter({
    required this.progress,
    required this.hand,
    required this.skin,
    required this.showNumerals,
    required this.showCenter,
    this.centerText,
    this.label,
  });

  final double progress;
  final Color hand;
  final AppSkin skin;
  final bool showNumerals;
  final bool showCenter;
  final String? centerText;
  final String? label;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 6;

    // Dial face.
    canvas.drawCircle(center, radius, Paint()..color = skin.inkSurface);

    // Brass bezel: outer + inner ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06
        ..color = skin.accent,
    );
    canvas.drawCircle(
      center,
      radius * 0.88,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = skin.accentMuted,
    );

    // Minute ticks.
    if (showNumerals) {
      final tick = Paint()
        ..color = skin.paperFaint
        ..strokeWidth = 1;
      for (var i = 0; i < 60; i++) {
        final a = (i / 60) * 2 * math.pi - math.pi / 2;
        final outer = radius * 0.86;
        final inner = radius * (i % 5 == 0 ? 0.78 : 0.82);
        canvas.drawLine(
          center + Offset(math.cos(a), math.sin(a)) * inner,
          center + Offset(math.cos(a), math.sin(a)) * outer,
          tick,
        );
      }
      // Roman numerals.
      for (var i = 0; i < 12; i++) {
        final a = (i / 12) * 2 * math.pi - math.pi / 2;
        final pos = center + Offset(math.cos(a), math.sin(a)) * (radius * 0.66);
        _paintText(
          canvas,
          _roman[i],
          pos,
          GoogleFonts.getFont(
            skin.displayFontFamily,
            fontSize: radius * 0.13,
            fontWeight: FontWeight.w600,
            color: skin.paper,
          ),
        );
      }
    }

    // Remaining-time arc on the bezel (shape cue, shrinks with time).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.88),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.04
        ..strokeCap = StrokeCap.round
        ..color = hand,
    );

    // Sweeping hand (elapsed fraction, clockwise from 12).
    final elapsed = 1 - progress.clamp(0.0, 1.0);
    final handAngle = -math.pi / 2 + 2 * math.pi * elapsed;
    final handPaint = Paint()
      ..color = hand
      ..strokeWidth = radius * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(math.cos(handAngle), math.sin(handAngle)) * radius * 0.62,
      handPaint,
    );
    // Counterweight tail.
    canvas.drawLine(
      center,
      center - Offset(math.cos(handAngle), math.sin(handAngle)) * radius * 0.16,
      handPaint,
    );
    // Center hub.
    canvas.drawCircle(center, radius * 0.05, Paint()..color = skin.accent);

    // Engraved MM:SS sub-dial below centre.
    if (showCenter && centerText != null) {
      _paintText(
        canvas,
        centerText!,
        center + Offset(0, radius * 0.34),
        GoogleFonts.getFont(
          skin.digitFontFamily,
          fontSize: radius * 0.2,
          fontWeight: FontWeight.w700,
          color: skin.paper,
        ),
      );
    }
    if (label != null) {
      _paintText(
        canvas,
        label!.toUpperCase(),
        center - Offset(0, radius * 0.3),
        GoogleFonts.getFont(
          skin.displayFontFamily,
          fontSize: radius * 0.085,
          letterSpacing: 1.5,
          color: skin.paperFaint,
        ),
      );
    }
  }

  void _paintText(Canvas canvas, String text, Offset at, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PocketWatchPainter old) =>
      old.progress != progress ||
      old.hand != hand ||
      old.skin.id != skin.id ||
      old.centerText != centerText ||
      old.label != label;
}
