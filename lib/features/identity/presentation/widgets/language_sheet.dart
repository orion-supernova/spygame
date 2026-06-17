import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/skin_context.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';

Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.skin.inkRaised,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final entries = <_LanguageEntry>[
      _LanguageEntry(code: 'en', name: l10n.langNameEn),
      _LanguageEntry(code: 'tr', name: l10n.langNameTr),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.skin.inkOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(width: 28, height: 2, color: context.skin.accent),
                const SizedBox(width: 10),
                Text(
                  l10n.langSelectorLabel,
                  style: context.skin.monoStyle(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: context.skin.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final entry in entries) ...[
              _LanguageRow(
                entry: entry,
                selected: locale.languageCode == entry.code,
                onTap: () async {
                  await Haptics.selection();
                  await ref.read(localeProvider.notifier).setLocale(entry.code);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
              ),
              if (entry != entries.last)
                Divider(height: 1, color: context.skin.inkOutline),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageEntry {
  const _LanguageEntry({required this.code, required this.name});
  final String code;
  final String name;
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _LanguageEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? context.skin.paper : context.skin.paperMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? context.skin.accent : Colors.transparent,
                border: Border.all(
                  color: selected ? context.skin.accent : context.skin.inkOutline,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? Icon(Icons.check, size: 14, color: context.skin.ink)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
