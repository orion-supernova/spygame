import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// A bouncing chevron + label nudging the user to scroll for the locations.
/// Wraps a tap callback and respects an externally-driven [opacity] so it can
/// fade out as the user starts scrolling.
class ScrollHint extends StatefulWidget {
  const ScrollHint({
    super.key,
    required this.onTap,
    required this.opacity,
    this.label = 'See locations',
  });

  final VoidCallback onTap;
  final double opacity;
  final String label;

  @override
  State<ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<ScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _bobCurve = CurvedAnimation(
    parent: _bob,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.opacity < 0.05,
      child: Opacity(
        opacity: widget.opacity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: AppTypography.mono(
                    size: 11,
                    letterSpacing: 2.4,
                    color: AppColors.paperFaint,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _bobCurve,
                  builder: (context, _) {
                    final dy = _bobCurve.value * 4;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.paperFaint,
                        size: 26,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
