import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ReadyButton extends StatelessWidget {
  const ReadyButton({
    super.key,
    required this.ready,
    required this.onToggle,
  });

  final bool ready;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 56,
        decoration: BoxDecoration(
          color: ready ? AppColors.lime : AppColors.inkRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: ready ? AppColors.lime : AppColors.inkOutline,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: ready ? AppColors.ink : AppColors.paper,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ready)
                const Icon(Icons.check_rounded, color: AppColors.ink),
              if (ready) const SizedBox(width: 8),
              Text(ready ? "I'M READY" : 'TAP WHEN READY'),
            ],
          ),
        ),
      ),
    );
  }
}
