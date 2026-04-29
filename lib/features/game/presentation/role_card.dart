import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/role.dart';

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
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && !_revealed) {
        _revealed = true;
        Haptics.medium();
        _flip.forward();
        setState(() {});
      }
    });

  bool _revealed = false;

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
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
          SizedBox(
            width: 72,
            height: 72,
            child: AnimatedBuilder(
              animation: progress,
              builder: (_, __) {
                final t = progress.value;
                final iconColor = Color.lerp(
                  AppColors.paperFaint,
                  AppColors.lime,
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
                        color: AppColors.lime,
                        backgroundColor: AppColors.inkOutline,
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
            style: AppTypography.mono(
              size: 12,
              weight: FontWeight.w600,
              letterSpacing: 2.4,
              color: AppColors.paper,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).roleBackHint,
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
    final l10n = AppLocalizations.of(context);
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
                isSpy ? l10n.roleFrontCover : l10n.roleFrontYouAre,
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
              l10n.roleTheSpy,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.signalRed,
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
              l10n.roleFrontAt,
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
            l10n.roleReleaseToHide,
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
