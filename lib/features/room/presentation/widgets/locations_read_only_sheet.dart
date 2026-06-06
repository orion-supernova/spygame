import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../marketplace/data/marketplace_providers.dart';
import '../../data/locations_picker_repository.dart';

/// Non-host read-only mirror of the host's enabled-locations selection.
/// Subscribes to the server query so the list updates live as the host
/// toggles in their picker — a row disappears the moment it's disabled.
class LocationsReadOnlySheet extends ConsumerStatefulWidget {
  const LocationsReadOnlySheet({super.key, required this.code});

  final String code;

  static Future<void> show(BuildContext context, {required String code}) {
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
        builder: (_, __) => LocationsReadOnlySheet(code: code),
      ),
    );
  }

  @override
  ConsumerState<LocationsReadOnlySheet> createState() =>
      _LocationsReadOnlySheetState();
}

class _LocationsReadOnlySheetState
    extends ConsumerState<LocationsReadOnlySheet> {
  Set<String> _expanded = const {};

  void _toggleExpanded(String key) {
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
    final enabledAsync = ref.watch(
      enabledLocationsForRoomProvider(widget.code),
    );
    final bundlesAsync = ref.watch(bundlesProvider);
    final bundleTitles = bundlesAsync.maybeWhen(
      data: (bundles) {
        final map = <String, String>{};
        for (final b in bundles as List) {
          final dynamic dyn = b;
          map[dyn.slug as String] = dyn.title as String;
        }
        return map;
      },
      orElse: () => const <String, String>{},
    );

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
                  l10n.locationsReadOnlySheetTitle,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.locationsReadOnlySheetSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.paperMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: enabledAsync.when(
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
              data: (rows) => _ReadOnlyBody(
                rows: rows,
                bundleTitles: bundleTitles,
                freeLabel: l10n.locationsSheetSectionFree,
                expanded: _expanded,
                onToggleExpanded: _toggleExpanded,
              ),
            ),
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
}

const String _kFreeKey = '__free__';

class _ReadOnlyBody extends StatelessWidget {
  const _ReadOnlyBody({
    required this.rows,
    required this.bundleTitles,
    required this.freeLabel,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final List<PickerLocation> rows;
  final Map<String, String> bundleTitles;
  final String freeLabel;
  final Set<String> expanded;
  final ValueChanged<String> onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final grouped = <String?, List<PickerLocation>>{};
    for (final r in rows) {
      grouped.putIfAbsent(r.bundleSlug, () => []).add(r);
    }
    final bundleKeys = grouped.keys.where((k) => k != null).toList()
      ..sort(
        (a, b) => (bundleTitles[a] ?? a!).compareTo(bundleTitles[b] ?? b!),
      );
    final sections = <_SectionData>[
      if (grouped[null] != null)
        _SectionData(key: _kFreeKey, title: freeLabel, rows: grouped[null]!),
      for (final slug in bundleKeys)
        _SectionData(
          key: slug!,
          title: bundleTitles[slug] ?? slug,
          rows: grouped[slug]!,
        ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final s = sections[i];
        return _Section(
          sectionKey: s.key,
          title: s.title,
          rows: s.rows,
          isExpanded: expanded.contains(s.key),
          onToggleExpanded: onToggleExpanded,
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

class _Section extends StatelessWidget {
  const _Section({
    required this.sectionKey,
    required this.title,
    required this.rows,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final String sectionKey;
  final String title;
  final List<PickerLocation> rows;
  final bool isExpanded;
  final ValueChanged<String> onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onToggleExpanded(sectionKey),
            behavior: HitTestBehavior.opaque,
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
                    '${rows.length}',
                    style: AppTypography.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.paperFaint,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: AppColors.paperMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: AppColors.inkOutline.withValues(alpha: 0.5),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Text(
                            rows[i].name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.paper),
                          ),
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
