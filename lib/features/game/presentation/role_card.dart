import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/skin_context.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/role.dart';
import 'widgets/role_card_frames.dart';

/// Press-and-hold to reveal so a glance at someone else's screen doesn't leak
/// the role. A ring around the fingerprint fills as the press registers;
/// releasing flips the card back face-down.
class RoleCard extends StatefulWidget {
  const RoleCard({super.key, required this.role});
  final Role? role;

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && !_revealed) {
        _revealed = true;
        Haptics.medium();
        _flip.forward();
        _recognizer?.lockIn();
        setState(() {});
      }
    })
    ..addListener(_tickHaptic);

  _PressHoldRecognizer? _recognizer;
  bool _revealed = false;
  int _hapticStep = 0;

  void _tickHaptic() {
    if (_revealed) return;
    // Convex curve so clicks bunch near completion — feels like a ratchet
    // tightening as the ring fills.
    final v = _press.value;
    final step = (v * v * 12).floor();
    if (step > _hapticStep) {
      _hapticStep = step;
      Haptics.selection();
    } else if (step < _hapticStep) {
      _hapticStep = step;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _press.dispose();
    super.dispose();
  }

  void _release() {
    if (_revealed) {
      _revealed = false;
      _flip.reverse();
    }
    _press.reverse();
    _hapticStep = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        _PressHoldRecognizer:
            GestureRecognizerFactoryWithHandlers<_PressHoldRecognizer>(
          () => _PressHoldRecognizer(),
          (recognizer) {
            _recognizer = recognizer;
            recognizer.onStart = () => _press.forward();
            recognizer.onEnd = _release;
          },
        ),
      },
      child: AnimatedBuilder(
        animation: _flip,
        builder: (_, _) {
          final t = _flip.value;
          final angle = t * 3.14159; // pi
          final showFront = t > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _Front(role: role),
                  )
                : _Back(progress: _press),
          );
        },
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return RoleCardFrame(
      isBack: true,
      isSpy: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          SizedBox(
            width: 72,
            height: 72,
            child: AnimatedBuilder(
              animation: progress,
              builder: (_, _) {
                final t = progress.value;
                final iconColor = Color.lerp(
                  skin.paperFaint,
                  skin.accent,
                  t,
                )!;
                final scale = 1.0 + 0.12 * t;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: t,
                        strokeWidth: 2.5,
                        color: skin.accent,
                        backgroundColor: skin.inkOutline,
                      ),
                    ),
                    Transform.scale(
                      scale: scale,
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 44,
                        color: iconColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).roleBackEyebrow,
            style: skin.monoStyle(
              size: 12,
              letterSpacing: 2.4,
              color: skin.paper,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).roleBackHint,
            style: skin.monoStyle(
              size: 11,
              weight: FontWeight.w500,
              letterSpacing: 2.0,
              color: skin.paperFaint,
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.role});
  final Role? role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skin = context.skin;
    if (role == null) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: skin.inkRaised,
          borderRadius: BorderRadius.circular(skin.cardRadius),
        ),
        child: CircularProgressIndicator(color: skin.accent),
      );
    }
    final isSpy = role!.isSpy;
    final accent = isSpy ? skin.danger : skin.accent;
    return RoleCardFrame(
      isBack: false,
      isSpy: isSpy,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.roleYourRole,
                style: skin.monoStyle(
                  size: 11,
                  letterSpacing: 2.2,
                  color: accent,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isSpy) ...[
            Text(
              l10n.roleTheSpy,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: skin.danger,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.roleSpySubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: skin.paper),
            ),
          ] else ...[
            Text(
              role!.label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: skin.paper,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.roleFrontAt,
              style: skin.monoStyle(
                size: 11,
                letterSpacing: 2.2,
                color: skin.paperFaint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role!.locationName ?? '—',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: skin.accent,
                  ),
            ),
          ],
          const Spacer(),
          Text(
            l10n.roleReleaseToHide,
            style: skin.monoStyle(
              size: 10,
              weight: FontWeight.w500,
              letterSpacing: 1.4,
              color: skin.paperFaint,
            ),
          ),
          ],
        ),
      ),
    );
  }
}

/// Joins the gesture arena on pointer-down but doesn't claim it. The press
/// animation runs as visual feedback; if the user drags far enough during
/// the animation the parent scrollable wins the arena and our gesture is
/// rejected (press reverses, scroll happens). Once the press animation hits
/// the lock-in point, [lockIn] claims the arena so subsequent finger
/// movement can't cancel the reveal.
class _PressHoldRecognizer extends OneSequenceGestureRecognizer {
  VoidCallback? onStart;
  VoidCallback? onEnd;
  int? _activePointer;
  bool _locked = false;
  bool _ended = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _locked = false;
    _ended = false;
    startTrackingPointer(event.pointer);
    onStart?.call();
  }

  void lockIn() {
    if (_activePointer == null || _locked || _ended) return;
    _locked = true;
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _finish();
    }
  }

  void _finish() {
    if (_ended || _activePointer == null) return;
    _ended = true;
    final pointer = _activePointer!;
    _activePointer = null;
    stopTrackingPointer(pointer);
    if (!_locked) resolve(GestureDisposition.rejected);
    onEnd?.call();
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _activePointer && !_locked && !_ended) {
      _ended = true;
      _activePointer = null;
      stopTrackingPointer(pointer);
      onEnd?.call();
    }
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'press hold';
}
