import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.progress,
    required this.seconds,
    required this.totalSeconds,
    required this.label,
  });

  final double progress; // 0..1, remaining/total
  final int seconds;
  final int totalSeconds;
  final String label;

  Color get _accent {
    if (seconds <= 10) return AppColors.signalRed;
    if (seconds <= 30) return AppColors.amber;
    return AppColors.lime;
  }

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _RingPainter(progress: progress, color: _accent),
            size: Size.infinite,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 2.4,
                  color: AppColors.paperFaint,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _formatted,
                style: AppTypography.mono(
                  size: 80,
                  weight: FontWeight.w700,
                  letterSpacing: -2,
                  color: _accent,
                ).copyWith(height: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = AppColors.inkOutline;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..color = color;
    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
