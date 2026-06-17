import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/skin_context.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'language_sheet.dart';

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).langSelectorLabel,
      child: GestureDetector(
        onTap: () async {
          await Haptics.selection();
          if (!context.mounted) return;
          await showLanguageSheet(context);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.skin.inkRaised,
            shape: BoxShape.circle,
            border: Border.all(color: context.skin.inkOutline, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.language,
            size: 20,
            color: context.skin.paperMuted,
          ),
        ),
      ),
    );
  }
}
