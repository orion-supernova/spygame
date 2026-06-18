import 'package:flutter/material.dart';

import '../../../../core/theme/app_skin.dart';
import '../../../../core/theme/skin_context.dart';
import '../countdown_ring.dart';

/// Cyberpunk timer: a glowing digital readout. Each digit is drawn over a
/// faint "all-segments" ghost so it reads like a seven-segment display.
/// The brief refresh flicker fires only when the whole-second value changes
/// (never per animation frame) and is skipped under reduced motion.
class DigitalCountdown extends StatefulWidget {
  const DigitalCountdown({
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
  State<DigitalCountdown> createState() => _DigitalCountdownState();
}

class _DigitalCountdownState extends State<DigitalCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant DigitalCountdown old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) {
      final reduce = MediaQuery.of(context).disableAnimations ||
          MediaQuery.of(context).accessibleNavigation;
      if (!reduce) _flicker.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final accent = countdownAccent(skin, widget.seconds);
    final text = formatCountdown(widget.seconds);
    final size = widget.hero ? 68.0 : 22.0;

    final readout = AnimatedBuilder(
      animation: _flicker,
      builder: (_, _) {
        // Blip dim then back to full as the value refreshes.
        final opacity = 0.55 + 0.45 * _flicker.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final ch in text.characters)
              _DigitCell(
                char: ch,
                size: size,
                skin: skin,
                lit: accent,
                glow: skin.cardGlow,
                opacity: opacity,
              ),
          ],
        );
      },
    );

    if (!widget.hero) {
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
            readout,
            const SizedBox(width: 12),
            Text(
              widget.label,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.label,
          style: skin.monoStyle(
            size: 11,
            letterSpacing: 2.4,
            color: skin.paperFaint,
          ),
        ),
        const SizedBox(height: 12),
        FittedBox(fit: BoxFit.scaleDown, child: readout),
        const SizedBox(height: 12),
        // Thin progress bar — a shape cue that reinforces the colour shift.
        SizedBox(
          width: size * 4.2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: widget.progress,
              minHeight: 3,
              backgroundColor: skin.inkOutline,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
      ],
    );
  }
}

class _DigitCell extends StatelessWidget {
  const _DigitCell({
    required this.char,
    required this.size,
    required this.skin,
    required this.lit,
    required this.glow,
    required this.opacity,
  });

  final String char;
  final double size;
  final AppSkin skin;
  final Color lit;
  final bool glow;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isColon = char == ':';
    final ghostChar = isColon ? ':' : '8';
    final base = skin.digitStyle(size: size);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isColon ? size * 0.02 : size * 0.04),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Unlit "ghost" segments behind the live digit.
          Text(ghostChar,
              style: base.copyWith(color: skin.inkOutline.withValues(alpha: 0.5))),
          Opacity(
            opacity: opacity,
            child: Text(
              char,
              style: base.copyWith(
                color: lit,
                shadows: glow
                    ? [Shadow(color: lit.withValues(alpha: 0.8), blurRadius: size * 0.25)]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
