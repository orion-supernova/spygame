import 'package:flutter/material.dart';

/// Identity-driven palette for "Where am I?". Inspired by noir/spy aesthetics:
/// deep ink background, paper foreground, electric lime as the primary CTA,
/// signal red reserved for the spy reveal.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF0B0D12);
  static const Color inkRaised = Color(0xFF14171F);
  static const Color inkSurface = Color(0xFF1B1F2A);
  static const Color inkOutline = Color(0xFF2B3140);

  static const Color paper = Color(0xFFF4F2EC);
  static const Color paperMuted = Color(0xFFB8B5A8);
  static const Color paperFaint = Color(0xFF6B6E78);

  static const Color lime = Color(0xFFC6FF4D);
  static const Color limeMuted = Color(0xFF8FB833);
  static const Color amber = Color(0xFFFFB547);
  static const Color signalRed = Color(0xFFFF5A5F);

  static const Color success = Color(0xFF7BE495);
  static const Color warning = amber;
  static const Color danger = signalRed;
}
