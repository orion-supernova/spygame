import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../marketplace/data/marketplace_providers.dart';
import '../../data/locations_picker_repository.dart';
import '../../domain/room_repository.dart';

/// Host-only locations picker. Sectioned by bundle (Free + each owned
/// bundle), each section has a per-row checkbox + bulk-toggle. Edits are
/// pushed to the server immediately on toggle (full-set replace, so
/// races resolve to the latest tap). The bottom DONE button just closes
/// the sheet — there's no separate save step.
class LocationsSheet extends ConsumerStatefulWidget {
  const LocationsSheet({
    super.key,
    required this.code,
    required this.currentDisabled,
    required this.repository,
  });

  final String code;
  final Set<String> currentDisabled;
  final RoomRepository repository;

  static Future<void> show(
    BuildContext context, {
    required String code,
    required Set<String> currentDisabled,
    required RoomRepository repository,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.inkRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => LocationsSheet(
          code: code,
          currentDisabled: currentDisabled,
          repository: repository,
        ),
      ),
    );
  }

  @override
  ConsumerState<LocationsSheet> createState() => _LocationsSheetState();
}

class _LocationsSheetState extends ConsumerState<LocationsSheet> {
  late Set<String> _disabled;
  // Section keys that are currently expanded. The classic pool keys to
  // `_kFreeKey`; bundles key to their slug. Always starts empty — users
  // expect "tap to expand," not "everything's already open."
  Set<String> _expanded = const {};

  @override
  void initState() {
    super.initState();
    _disabled = {...widget.currentDisabled};
  }

  Future<void> _push() async {
    try {
      await widget.repository.setDisabledLocations(
        code: widget.code,
        disabledLocationIds: _disabled.toList(),
      );
    } catch (_) {
      // Tolerate; the mutation will be retried on the next change. The
      // server's snapshot at startGame is what matters, and the watchRoom
      // stream will re-sync the visible state.
    }
  }

  void _toggleOne(String id) {
    Haptics.selection();
    setState(() {
      if (_disabled.contains(id)) {
        _disabled.remove(id);
      } else {
        _disabled.add(id);
      }
    });
    _push();
  }

  void _toggleSection(List<PickerLocation> rows) {
    Haptics.selection();
    final allDisabled = rows.every((r) => _disabled.contains(r.id));
    setState(() {
      if (allDisabled) {
        for (final r in rows) {
          _disabled.remove(r.id);
        }
      } else {
        for (final r in rows) {
          _disabled.add(r.id);
        }
      }
    });
    _push();
  }

  void _toggleExpanded(String key) {
    Haptics.selection();
    setState(() {
      final next = {..._expanded};
      if (next.contains(key)) {
        next.remove(key);
      } else {
        next.add(key);
      }
      _expanded = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final picker = ref.watch(locationsForPickerProvider);
    final bundlesAsync = ref.watch(bundlesProvider);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inkOutline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 6, 28, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.locationsSheetTitle,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.locationsSheetSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.paperMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                picker.maybeWhen(
                  data: (rows) {
                    final total = rows.length;
                    final enabled =
                        rows.where((r) => !_disabled.contains(r.id)).length;
                    return _TotalBadge(enabled: enabled, total: total);
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: picker.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  e.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.signalRed,
                  ),
                ),
              ),
              data: (rows) => _Body(
                rows: rows,
                bundleTitles: _bundleTitlesFromAsync(bundlesAsync),
                disabled: _disabled,
                freeLabel: l10n.locationsSheetSectionFree,
                expanded: _expanded,
                onToggleExpanded: _toggleExpanded,
                onToggleOne: _toggleOne,
                onToggleSection: _toggleSection,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: _BrowseMarketplaceRow(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.locationsSheetDone),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _bundleTitlesFromAsync(AsyncValue<dynamic> bundlesAsync) {
    return bundlesAsync.maybeWhen(
      data: (bundles) {
        final result = <String, String>{};
        for (final b in (bundles as List)) {
          // Bundle has `slug` and `title` fields. Iterating in a
          // duck-typed way avoids a hard import dance for what's
          // effectively a string→string projection.
          final dynamic dyn = b;
          result[dyn.slug as String] = dyn.title as String;
        }
        return result;
      },
      orElse: () => const <String, String>{},
    );
  }
}

/// Section key for the free pool. Bundle sections key to their slug.
const String _kFreeKey = '__free__';

class _Body extends StatelessWidget {
  const _Body({
    required this.rows,
    required this.bundleTitles,
    required this.disabled,
    required this.freeLabel,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onToggleOne,
    required this.onToggleSection,
  });

  final List<PickerLocation> rows;
  final Map<String, String> bundleTitles;
  final Set<String> disabled;
  final String freeLabel;
  final Set<String> expanded;
  final ValueChanged<String> onToggleExpanded;
  final ValueChanged<String> onToggleOne;
  final void Function(List<PickerLocation>) onToggleSection;

  @override
  Widget build(BuildContext context) {
    // Group rows by bundleSlug; null = the classic pool.
    final grouped = <String?, List<PickerLocation>>{};
    for (final r in rows) {
      grouped.putIfAbsent(r.bundleSlug, () => []).add(r);
    }
    final bundleKeys = grouped.keys.where((k) => k != null).toList()
      ..sort((a, b) =>
          (bundleTitles[a] ?? a!).compareTo(bundleTitles[b] ?? b!));
    final orderedSections = <_SectionData>[
      if (grouped[null] != null)
        _SectionData(
          key: _kFreeKey,
          title: freeLabel,
          rows: grouped[null]!,
        ),
      for (final slug in bundleKeys)
        _SectionData(
          key: slug!,
          title: bundleTitles[slug] ?? slug,
          rows: grouped[slug]!,
        ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      itemCount: orderedSections.length,
      itemBuilder: (context, i) {
        final s = orderedSections[i];
        return _Section(
          sectionKey: s.key,
          title: s.title,
          rows: s.rows,
          disabled: disabled,
          isExpanded: expanded.contains(s.key),
          onToggleExpanded: onToggleExpanded,
          onToggleOne: onToggleOne,
          onToggleSection: onToggleSection,
        );
      },
    );
  }
}

class _SectionData {
  const _SectionData({
    required this.key,
    required this.title,
    required this.rows,
  });
  final String key;
  final String title;
  final List<PickerLocation> rows;
}

/// In-context entry point to the marketplace from inside the locations
/// picker. Always visible — covers both "no bundles owned" and "want
/// more" without needing a conditional empty-hint string. Pushes the
/// marketplace on top of the sheet (sheet stays mounted underneath), so
/// closing the marketplace reveals the picker again with refreshed data
/// — `locationsForPickerProvider` is autoDispose and watches
/// `ownedBundlesProvider`, so a freshly-mock-purchased bundle appears
/// as a new section without re-opening the sheet.
class _BrowseMarketplaceRow extends StatelessWidget {
  const _BrowseMarketplaceRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        splashColor: AppColors.lime.withValues(alpha: 0.06),
        highlightColor: AppColors.lime.withValues(alpha: 0.04),
        onTap: () {
          Haptics.light();
          context.push(AppRoute.marketplace);
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.5),
            borderRadius: radius,
            border: Border.all(color: AppColors.inkOutline),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.locationsSheetBrowseMarketplace,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.paperMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.lime,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.enabled, required this.total});
  final int enabled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allOff = enabled == 0 && total > 0;
    final color = allOff ? AppColors.signalRed : AppColors.lime;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        l10n.locationsSheetTotalEnabled(enabled, total),
        style: AppTypography.mono(
          size: 11,
          weight: FontWeight.w700,
          letterSpacing: 1.6,
          color: color,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.sectionKey,
    required this.title,
    required this.rows,
    required this.disabled,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onToggleOne,
    required this.onToggleSection,
  });

  final String sectionKey;
  final String title;
  final List<PickerLocation> rows;
  final Set<String> disabled;
  final bool isExpanded;
  final ValueChanged<String> onToggleExpanded;
  final ValueChanged<String> onToggleOne;
  final void Function(List<PickerLocation>) onToggleSection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = rows.where((r) => !disabled.contains(r.id)).length;
    final allDisabled = enabled == 0;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tappable across the whole row to toggle expansion.
          // The bulk-toggle IconButton absorbs its own taps so it stays a
          // distinct affordance.
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onToggleExpanded(sectionKey),
              splashColor: AppColors.lime.withValues(alpha: 0.05),
              highlightColor: AppColors.lime.withValues(alpha: 0.03),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                child: Row(
                  children: [
                    Container(width: 22, height: 2, color: AppColors.lime),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: AppTypography.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 2.2,
                          color: AppColors.lime,
                        ),
                      ),
                    ),
                    Text(
                      l10n.locationsSheetSectionCount(enabled, rows.length),
                      style: AppTypography.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.paperFaint,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Bulk toggle: tap absorbed so it doesn't expand the
                    // section. Filled box = all on; empty = all off;
                    // dashed-style icon = mixed.
                    IconButton(
                      tooltip: l10n.locationsSheetToggleAll,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () => onToggleSection(rows),
                      icon: Icon(
                        enabled == rows.length
                            ? Icons.check_box_rounded
                            : enabled == 0
                                ? Icons.check_box_outline_blank_rounded
                                : Icons.indeterminate_check_box_rounded,
                        color: allDisabled
                            ? AppColors.paperFaint
                            : AppColors.lime,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Disclosure chevron. Collapsed = ▶ (closed; "tap
                    // to open"). Expanded = ▼ via 90° rotation. Avoids
                    // the prior "down arrow on a closed thing" confusion
                    // where a downward chevron on a collapsed section
                    // read as a checkmark/done state.
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Tooltip(
                        message: isExpanded
                            ? l10n.locationsSheetCollapse
                            : l10n.locationsSheetExpand,
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: AppColors.paperMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Animated expand/collapse. ClipRect is necessary so AnimatedSize
          // doesn't briefly overflow during the transition.
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: isExpanded ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.inkOutline),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0)
                          Container(
                            height: 1,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 14),
                            color:
                                AppColors.inkOutline.withValues(alpha: 0.5),
                          ),
                        _Row(
                          location: rows[i],
                          isEnabled: !disabled.contains(rows[i].id),
                          onToggle: () => onToggleOne(rows[i].id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.location,
    required this.isEnabled,
    required this.onToggle,
  });

  final PickerLocation location;
  final bool isEnabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                location.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isEnabled ? AppColors.paper : AppColors.paperFaint,
                  decoration:
                      isEnabled ? null : TextDecoration.lineThrough,
                  decorationColor: AppColors.paperFaint,
                  decorationThickness: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _Toggle(value: isEnabled, onTap: onToggle),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onTap});
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppColors.lime : AppColors.inkOutline,
            width: 1.5,
          ),
        ),
        child: value
            ? const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.ink,
              )
            : null,
      ),
    );
  }
}
