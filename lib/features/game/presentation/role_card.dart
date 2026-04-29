import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../domain/role.dart';

/// Long-press to reveal so a glance at someone else's screen doesn't leak
/// the role. Releasing flips the card back face-down.
class RoleCard extends StatefulWidget {
  const RoleCard({super.key, required this.role});
  final Role? role;

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  bool _revealed = false;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _set(bool reveal) {
    if (_revealed == reveal) return;
    _revealed = reveal;
    if (reveal) {
      Haptics.medium();
      _flip.forward();
    } else {
      _flip.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    return GestureDetector(
      onLongPressStart: (_) => _set(true),
      onLongPressEnd: (_) => _set(false),
      onLongPressCancel: () => _set(false),
      onTap: () {
        // Quick tap also briefly reveals.
        _set(true);
        Future<void>.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _set(false);
        });
      },
      child: AnimatedBuilder(
        animation: _flip,
        builder: (_, __) {
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
                : const _Back(),
          );
        },
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inkOutline, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fingerprint_rounded,
              size: 48, color: AppColors.paperFaint),
          const SizedBox(height: 14),
          Text(
            'YOUR ROLE',
            style: AppTypography.mono(
              size: 12,
              weight: FontWeight.w600,
              letterSpacing: 2.4,
              color: AppColors.paper,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TAP & HOLD TO REVEAL',
            style: AppTypography.mono(
              size: 11,
              weight: FontWeight.w500,
              letterSpacing: 2.0,
              color: AppColors.paperFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.role});
  final Role? role;

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.inkRaised,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const CircularProgressIndicator(color: AppColors.lime),
      );
    }
    final isSpy = role!.isSpy;
    final accent = isSpy ? AppColors.signalRed : AppColors.lime;
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSpy
            ? AppColors.signalRed.withValues(alpha: 0.12)
            : AppColors.inkRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent, width: 1.5),
      ),
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
                isSpy ? 'COVER ROLE' : 'YOU ARE',
                style: AppTypography.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: accent,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isSpy) ...[
            Text(
              'THE SPY',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.signalRed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t know the location.\nAsk questions, blend in, figure it out.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.paper),
            ),
          ] else ...[
            Text(
              role!.label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'AT',
              style: AppTypography.mono(
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 2.2,
                color: AppColors.paperFaint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role!.locationName ?? '—',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.lime,
                  ),
            ),
          ],
          const Spacer(),
          Text(
            'release to hide',
            style: AppTypography.mono(
              size: 10,
              weight: FontWeight.w500,
              letterSpacing: 1.4,
              color: AppColors.paperFaint,
            ),
          ),
        ],
      ),
    );
  }
}
