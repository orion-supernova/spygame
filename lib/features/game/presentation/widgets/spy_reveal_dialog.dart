import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Dossier-style modal that names the spy at round end. The spy line is
/// hidden behind a Telegram-style animated dust field; the device-holder
/// taps anywhere on the card to scatter the dust and reveal the name. The
/// card height is fixed so the frame doesn't jump on reveal.
class SpyRevealDialog extends StatefulWidget {
  const SpyRevealDialog({
    super.key,
    required this.roundIndex,
    required this.spyName,
  });

  final int roundIndex;
  final String spyName;

  @override
  State<SpyRevealDialog> createState() => _SpyRevealDialogState();
}

class _SpyRevealDialogState extends State<SpyRevealDialog>
    with TickerProviderStateMixin {
  static const _switchDuration = Duration(milliseconds: 220);
  static const _revealDuration = Duration(milliseconds: 360);

  late final Ticker _ticker;
  late final AnimationController _reveal;
  double _driftSec = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: _revealDuration);
    _ticker = createTicker((d) {
      setState(() => _driftSec = d.inMicroseconds / 1e6);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_revealed) return;
    setState(() => _revealed = true);
    Haptics.heavy();
    _reveal.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final spyName = Text(
      widget.spyName,
      textAlign: TextAlign.center,
      style: theme.textTheme.displaySmall?.copyWith(
        color: AppColors.paper,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Container(
          height: 300,
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.inkRaised,
              AppColors.signalRed,
              0.18,
            ),
            border: Border.all(color: AppColors.signalRed, width: 1.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.signalRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.spyRevealRoundEyebrow(widget.roundIndex),
                    style: AppTypography.mono(
                      size: 11,
                      letterSpacing: 2.2,
                      color: AppColors.signalRed,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Text(
                  l10n.spyRevealNameEyebrow,
                  textAlign: TextAlign.center,
                  style: AppTypography.mono(
                    size: 28,
                    weight: FontWeight.w800,
                    letterSpacing: 6,
                    color: AppColors.signalRed,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: _SpoilerCover(
                  drift: _driftSec,
                  reveal: _reveal,
                  child: spyName,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: _switchDuration,
                    child: _revealed
                        ? TextButton(
                            key: const ValueKey('continue'),
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.lime,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(l10n.spyRevealContinue),
                          )
                        : Text(
                            l10n.spyRevealTapHint,
                            key: const ValueKey('tap-hint'),
                            style: AppTypography.mono(
                              size: 12,
                              letterSpacing: 2.4,
                              color: AppColors.signalRed,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hides [child] behind an animated dust field (continuous drift) that
/// disperses radially when [reveal] animates from 0 → 1.
class _SpoilerCover extends StatelessWidget {
  const _SpoilerCover({
    required this.drift,
    required this.reveal,
    required this.child,
  });

  final double drift;
  final Animation<double> reveal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: reveal,
              builder: (_, _) => CustomPaint(
                painter: _SpoilerPainter(
                  drift: drift,
                  reveal: reveal.value,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.phase,
    required this.speedX,
    required this.speedY,
    required this.ampX,
    required this.ampY,
    required this.baseAlpha,
    required this.radius,
  });

  final double x;
  final double y;
  final double phase;
  final double speedX;
  final double speedY;
  final double ampX;
  final double ampY;
  final double baseAlpha;
  final double radius;
}

class _SpoilerPainter extends CustomPainter {
  _SpoilerPainter({required this.drift, required this.reveal});

  final double drift;
  final double reveal;

  static List<_Particle>? _cached;
  static Size? _cachedSize;

  static List<_Particle> _particlesFor(Size size) {
    if (_cached != null && _cachedSize == size) return _cached!;
    final rng = math.Random(0xC1A551F1ED);
    final count = math.max(60, (size.width * size.height / 220).round());
    final particles = List<_Particle>.generate(count, (_) {
      final r = rng.nextDouble();
      final radius = r < 0.55 ? 0.8 : (r < 0.9 ? 1.2 : 1.6);
      return _Particle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        phase: rng.nextDouble() * math.pi * 2,
        speedX: 0.9 + rng.nextDouble() * 2.2,
        speedY: 0.9 + rng.nextDouble() * 2.2,
        ampX: 1.5 + rng.nextDouble() * 3.5,
        ampY: 1.0 + rng.nextDouble() * 2.5,
        baseAlpha: 0.45 + rng.nextDouble() * 0.5,
        radius: radius,
      );
    });
    _cached = particles;
    _cachedSize = size;
    return particles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final particles = _particlesFor(size);

    // Cover wash matches the card's solid background so the text
    // disappears into the card itself rather than into a visible bar.
    final washColor = Color.lerp(
      AppColors.inkRaised,
      AppColors.signalRed,
      0.18,
    )!;
    final washAlpha = (1 - reveal).clamp(0.0, 1.0);
    if (washAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = washColor.withValues(alpha: washAlpha),
      );
    }

    final t = drift; // monotonic seconds; speeds are in rad/s
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scatter = reveal * reveal * 28.0;
    final particleAlpha = (1 - reveal).clamp(0.0, 1.0);
    if (particleAlpha <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final dx = math.sin(t * p.speedX + p.phase) * p.ampX;
      final dy = math.cos(t * p.speedY + p.phase) * p.ampY;
      var px = p.x + dx;
      var py = p.y + dy;

      if (scatter > 0) {
        final rx = px - cx;
        final ry = py - cy;
        final mag = math.sqrt(rx * rx + ry * ry);
        if (mag > 0.0001) {
          px += (rx / mag) * scatter;
          py += (ry / mag) * scatter;
        }
      }

      paint.color = AppColors.paper
          .withValues(alpha: p.baseAlpha * particleAlpha);
      canvas.drawCircle(Offset(px, py), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpoilerPainter old) =>
      old.drift != drift || old.reveal != reveal;
}
