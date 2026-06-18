import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_skin.dart';
import '../../../../core/theme/skin_context.dart';
import '../../../../core/theme/skin_providers.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../marketplace/data/marketplace_providers.dart';
import '../../../marketplace/domain/bundle.dart';
import '../../data/room_providers.dart';

/// Host-only bottom sheet to pick the room's active theme skin. Lists the
/// default (Classic) look plus every `theme` bundle the host owns. Selecting
/// one calls `setRoomTheme`, which syncs the skin to every player.
Future<void> showThemePicker({
  required BuildContext context,
  required WidgetRef ref,
  required String code,
  required String? currentSlug,
}) async {
  final l10n = AppLocalizations.of(context);
  final owned = ref.read(ownedBundlesProvider);
  final catalog = ref.read(bundlesProvider).valueOrNull ?? const <Bundle>[];
  final ownedThemes = catalog
      .where(
        (b) => b.category == BundleCategory.theme && owned.contains(b.slug),
      )
      .toList();

  // Warm the decorative fonts for owned themes now (while the host browses)
  // so applying a skin doesn't flash a fallback face on first paint.
  for (final b in ownedThemes) {
    final s = AppSkin.byId(skinIdFromSlug(b.slug));
    GoogleFonts.getFont(s.displayFontFamily);
    GoogleFonts.getFont(s.bodyFontFamily);
  }

  Future<void> select(String? slug) async {
    unawaited(Haptics.selection());
    Navigator.of(context).pop();
    await ref
        .read(roomRepositoryProvider)
        .setRoomTheme(code: code, slug: slug);
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.skin.inkRaised,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final skin = sheetCtx.skin;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.lobbyThemeSheetTitle,
                style: Theme.of(sheetCtx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.lobbyThemeSheetSubtitle,
                style: Theme.of(sheetCtx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: skin.paperMuted),
              ),
              const SizedBox(height: 16),
              // Default / Classic look (clears activeThemeSlug).
              _ThemeOption(
                skin: AppSkin.noir,
                label: l10n.lobbyThemeDefault,
                selected: currentSlug == null,
                onTap: () => select(null),
              ),
              for (final b in ownedThemes) ...[
                const SizedBox(height: 10),
                _ThemeOption(
                  skin: AppSkin.byId(skinIdFromSlug(b.slug)),
                  label: b.title,
                  selected: currentSlug == b.slug,
                  onTap: () => select(b.slug),
                ),
              ],
              if (ownedThemes.isEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  l10n.lobbyThemeNoneOwned,
                  style: Theme.of(sheetCtx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: skin.paperFaint),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.skin,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// The skin this option represents — drives the preview swatch so the host
  /// sees the actual palette/typeface before applying.
  final AppSkin skin;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = context.skin;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: chrome.inkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? chrome.accent : chrome.inkOutline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _Swatch(skin: skin),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: chrome.paper),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: chrome.accent, size: 22)
            else
              Icon(
                Icons.circle_outlined,
                color: chrome.paperFaint,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

/// A miniature of the skin: its ink background, a sample "Aa" in the skin's
/// display face, and accent + secondary dots.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.skin});
  final AppSkin skin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: skin.ink,
        borderRadius: BorderRadius.circular(skin.cardRadius.clamp(2, 12)),
        border: Border.all(color: skin.inkOutline, width: skin.cardBorderWidth),
        boxShadow: skin.cardGlow
            ? [BoxShadow(color: skin.accent.withValues(alpha: 0.35), blurRadius: 8)]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Aa',
            style: GoogleFonts.getFont(skin.displayFontFamily).copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: skin.paper,
              height: 1.0,
            ),
          ),
          Positioned(
            right: 5,
            bottom: 4,
            child: Row(
              children: [
                _Dot(color: skin.accent),
                const SizedBox(width: 3),
                _Dot(color: skin.secondary),
              ],
            ),
          ),
          // Hint at the bespoke timer this skin uses.
          Positioned(
            left: 4,
            top: 3,
            child: Icon(
              _timerIcon(skin.timerStyle),
              size: 11,
              color: skin.accent.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  IconData _timerIcon(SkinTimerStyle style) => switch (style) {
        SkinTimerStyle.ring => Icons.timelapse_rounded,
        SkinTimerStyle.digital => Icons.dialpad_rounded,
        SkinTimerStyle.flipClock => Icons.calendar_view_day_rounded,
        SkinTimerStyle.pocketWatch => Icons.schedule_rounded,
      };
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
