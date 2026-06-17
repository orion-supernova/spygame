import 'package:flutter/material.dart';

import '../../../../core/theme/app_skin.dart';
import '../../../../core/theme/skin_context.dart';

/// Wraps the role-card content (the existing `_Front`/`_Back` columns) in a
/// bespoke per-theme frame chosen by `context.skin.roleCardStyle`. The frame
/// owns the fixed 220 height so the flip geometry and press-to-reveal hit
/// area stay identical across themes; only the chrome changes.
class RoleCardFrame extends StatelessWidget {
  const RoleCardFrame({
    super.key,
    required this.child,
    required this.isSpy,
    required this.isBack,
  });

  static const double height = 220;

  final Widget child;
  final bool isSpy;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final accent = isSpy ? skin.danger : skin.accent;
    final fill = isSpy ? Color.lerp(skin.inkRaised, skin.danger, 0.10)! : skin.inkRaised;
    // Back face uses a quiet outline; front face uses the role accent.
    final border = isBack ? skin.inkOutline : accent;

    return switch (skin.roleCardStyle) {
      SkinRoleCardStyle.plain => _plain(skin, fill, border),
      SkinRoleCardStyle.hud => _hud(skin, fill, accent, border),
      SkinRoleCardStyle.wantedPoster => _wanted(skin, fill, accent, border),
      SkinRoleCardStyle.callingCard => _calling(skin, fill, accent, border),
    };
  }

  Widget _plain(AppSkin skin, Color fill, Color border) => Container(
        height: height,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(skin.cardRadius),
          border: Border.all(color: border, width: skin.cardBorderWidth),
        ),
        child: child,
      );

  // Cyberpunk: corner brackets + scanline sheen + optional glow.
  Widget _hud(AppSkin skin, Color fill, Color accent, Color border) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(color: border.withValues(alpha: 0.6), width: skin.cardBorderWidth),
        boxShadow: skin.cardGlow
            ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 16)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(skin.cardRadius),
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _HudPainter(accent: accent, line: skin.paper)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Wild West: heavy double border + corner nails (ornament).
  Widget _wanted(AppSkin skin, Color fill, Color accent, Color border) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(fill, skin.paper, 0.04),
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(color: border, width: skin.cardBorderWidth),
      ),
      child: Stack(
        children: [
          // Inset second rule for the poster look.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
          if (skin.ornament) ..._nails(accent),
        ],
      ),
    );
  }

  List<Widget> _nails(Color color) {
    const i = 11.0;
    Widget nail() => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    return [
      Positioned(left: i, top: i, child: nail()),
      Positioned(right: i, top: i, child: nail()),
      Positioned(left: i, bottom: i, child: nail()),
      Positioned(right: i, bottom: i, child: nail()),
    ];
  }

  // Victorian: engraved calling-card with inset brass rule + corner flourishes.
  Widget _calling(AppSkin skin, Color fill, Color accent, Color border) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(color: border, width: skin.cardBorderWidth),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
          if (skin.ornament) ..._flourishes(skin, accent),
        ],
      ),
    );
  }

  List<Widget> _flourishes(AppSkin skin, Color accent) {
    Widget glyph(String s) => Text(
          s,
          style: TextStyle(
            color: accent.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1,
          ),
        );
    return [
      Positioned(left: 12, top: 9, child: glyph('❧')),
      Positioned(
        right: 12,
        top: 9,
        child: Transform.flip(flipX: true, child: glyph('❧')),
      ),
      Positioned(left: 12, bottom: 9, child: glyph('❧')),
      Positioned(
        right: 12,
        bottom: 9,
        child: Transform.flip(flipX: true, child: glyph('❧')),
      ),
    ];
  }
}

class _HudPainter extends CustomPainter {
  _HudPainter({required this.accent, required this.line});
  final Color accent;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint horizontal scanline sheen.
    final scan = Paint()..color = line.withValues(alpha: 0.05);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    }
    // L-shaped corner brackets.
    final p = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 18.0;
    const m = 7.0;
    final w = size.width, h = size.height;
    // top-left
    canvas.drawLine(const Offset(m, m + len), const Offset(m, m), p);
    canvas.drawLine(const Offset(m, m), const Offset(m + len, m), p);
    // top-right
    canvas.drawLine(Offset(w - m, m + len), Offset(w - m, m), p);
    canvas.drawLine(Offset(w - m, m), Offset(w - m - len, m), p);
    // bottom-left
    canvas.drawLine(Offset(m, h - m - len), Offset(m, h - m), p);
    canvas.drawLine(Offset(m, h - m), Offset(m + len, h - m), p);
    // bottom-right
    canvas.drawLine(Offset(w - m, h - m - len), Offset(w - m, h - m), p);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m - len, h - m), p);
  }

  @override
  bool shouldRepaint(covariant _HudPainter old) =>
      old.accent != accent || old.line != line;
}
