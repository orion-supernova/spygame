import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_skin.dart';
import '../../../../core/theme/skin_context.dart';
import '../countdown_ring.dart';

/// Wild West timer: a mechanical split-flap "flip clock". Each digit is a
/// brass-framed card that folds to the next value once per whole second
/// (never per animation frame); the fold is skipped under reduced motion.
class FlipClockCountdown extends StatelessWidget {
  const FlipClockCountdown({
    super.key,
    required this.seconds,
    required this.label,
    this.hero = true,
  });

  final int seconds;
  final String label;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final accent = countdownAccent(skin, seconds);
    final text = formatCountdown(seconds);
    final w = hero ? 48.0 : 16.0;
    final h = hero ? 70.0 : 24.0;

    final cards = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in text.characters)
          if (ch == ':')
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.12),
              child: Text(
                ':',
                style: skin.digitStyle(size: h * 0.5, color: accent),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.05),
              child: _FlipDigit(
                digit: ch,
                width: w,
                height: h,
                skin: skin,
                digitColor: accent,
              ),
            ),
      ],
    );

    if (!hero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: skin.inkRaised,
          borderRadius: BorderRadius.circular(skin.cardRadius),
          border: Border.all(color: skin.inkOutline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            cards,
            const SizedBox(width: 12),
            Text(
              label,
              style: skin.monoStyle(size: 10, letterSpacing: 2, color: skin.paperFaint),
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
          label,
          style: skin.monoStyle(size: 11, letterSpacing: 2.4, color: skin.paperFaint),
        ),
        const SizedBox(height: 14),
        FittedBox(fit: BoxFit.scaleDown, child: cards),
      ],
    );
  }
}

class _FlipDigit extends StatefulWidget {
  const _FlipDigit({
    required this.digit,
    required this.width,
    required this.height,
    required this.skin,
    required this.digitColor,
  });

  final String digit;
  final double width;
  final double height;
  final AppSkin skin;
  final Color digitColor;

  @override
  State<_FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<_FlipDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late String _current = widget.digit;
  String _previous = '';
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _animating = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FlipDigit old) {
    super.didUpdateWidget(old);
    if (widget.digit != _current) {
      _previous = _current;
      _current = widget.digit;
      final reduce = MediaQuery.of(context).disableAnimations ||
          MediaQuery.of(context).accessibleNavigation;
      if (reduce) {
        setState(() => _animating = false);
      } else {
        _animating = true;
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  BoxDecoration get _cardDeco => BoxDecoration(
        color: widget.skin.inkSurface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: widget.skin.accentMuted),
      );

  Widget _face(String char) => Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        decoration: _cardDeco,
        child: Text(
          char,
          style: widget.skin
              .digitStyle(size: widget.height * 0.62, color: widget.digitColor),
        ),
      );

  // Top or bottom half of a single full-size face. OverflowBox forces the
  // card to its FULL height inside the half-height slot (otherwise the card
  // shrinks to fit and each half shows a whole digit — two stacked digits);
  // ClipRect then keeps only the relevant half.
  Widget _half(String char, {required bool top}) => SizedBox(
        width: widget.width,
        height: widget.height / 2,
        child: ClipRect(
          child: OverflowBox(
            minWidth: widget.width,
            maxWidth: widget.width,
            minHeight: widget.height,
            maxHeight: widget.height,
            alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
            child: _face(char),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!_animating) {
      // Static face: two halves with a hinge seam (Stack avoids a 1px
      // overflow that a Column of two half-cards + seam would cause).
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.topCenter, child: _half(_current, top: true)),
            Align(alignment: Alignment.bottomCenter, child: _half(_current, top: false)),
            Container(width: widget.width, height: 1, color: widget.skin.ink),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        final topLeafAngle = -(math.min(t, 0.5) / 0.5) * (math.pi / 2);
        final bottomLeafAngle =
            t < 0.5 ? math.pi / 2 : (1 - (t - 0.5) / 0.5) * (math.pi / 2);
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Static background: new top + (still) old bottom.
              Align(alignment: Alignment.topCenter, child: _half(_current, top: true)),
              Align(alignment: Alignment.bottomCenter, child: _half(_previous, top: false)),
              Container(width: widget.width, height: 1, color: widget.skin.ink),
              // Phase 1: old top folds down (hinge at bottom).
              if (t < 0.5)
                Align(
                  alignment: Alignment.topCenter,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(topLeafAngle),
                    child: _half(_previous, top: true),
                  ),
                ),
              // Phase 2: new bottom folds down (hinge at top).
              if (t >= 0.5)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(bottomLeafAngle),
                    child: _half(_current, top: false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
