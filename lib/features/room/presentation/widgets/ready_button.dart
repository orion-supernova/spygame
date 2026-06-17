import 'package:flutter/material.dart';

import '../../../../core/theme/skin_context.dart';
import '../../../../l10n/generated/app_localizations.dart';

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
          color: ready ? context.skin.accent : context.skin.inkRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: ready ? context.skin.accent : context.skin.inkOutline,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: ready ? context.skin.ink : context.skin.paper,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ready)
                Icon(Icons.check_rounded, color: context.skin.ink),
              if (ready) const SizedBox(width: 8),
              Text(
                ready
                    ? AppLocalizations.of(context).readyYes
                    : AppLocalizations.of(context).readyNo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
