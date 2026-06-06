import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter/material.dart';

import '../domain/bundle.dart';

/// Maps a bundle's `iconKey` (server-stored) to a Material icon. Keep
/// this map in lock-step with iconKeys used in `convex/bundles.ts`. Falls
/// back to a generic icon for unknown keys so a future server-only
/// addition still renders rather than crashing.
const Map<String, IconData> _iconForKey = <String, IconData>{
  'mosque': Icons.mosque_rounded,
  'electric_bolt': Icons.electric_bolt_rounded,
  'travel_explore': Icons.travel_explore_rounded,
  'rocket_launch': Icons.rocket_launch_rounded,
  'public': Icons.public_rounded,
  'local_cafe': Icons.local_cafe_rounded,
  'ramen_dining': Icons.ramen_dining_rounded,
  'sailing': Icons.sailing_rounded,
};

IconData _resolveIcon(String key) =>
    _iconForKey[key] ?? Icons.collections_bookmark_rounded;

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.parse(cleaned, radix: 16);
  // 6-digit hex → opaque ARGB.
  return Color(0xFF000000 | value);
}

class BundlesRepository {
  BundlesRepository(this._client);

  final ConvexClient _client;

  Future<List<Bundle>> list({required String locale}) async {
    final raw = await _client.query('bundles:list', {'locale': locale});
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<Object?, Object?>>()
        .map(_bundleFromMap)
        .toList();
  }

  Future<BundleDetail> detail({
    required String slug,
    required String locale,
  }) async {
    final raw = await _client.query(
      'bundles:detail',
      {'slug': slug, 'locale': locale},
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('bundles:detail returned non-map');
    }
    final bundle = _bundleFromMap(decoded);
    final locsRaw = decoded['locations'];
    final locations = <BundleLocation>[];
    if (locsRaw is List) {
      for (final l in locsRaw) {
        if (l is! Map) continue;
        final samples = (l['sampleRoles'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [];
        final roles =
            (l['roles'] as List?)?.whereType<String>().toList() ?? samples;
        locations.add(BundleLocation(
          name: l['name']?.toString() ?? '',
          sampleRoles: samples,
          roles: roles,
          totalRoles: (l['totalRoles'] as num?)?.toInt() ?? samples.length,
        ));
      }
    }
    return BundleDetail(bundle: bundle, locations: locations);
  }

  Bundle _bundleFromMap(Map<Object?, Object?> m) {
    return Bundle(
      slug: m['slug']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      tagline: m['tagline']?.toString() ?? '',
      priceDisplay: m['priceUsd']?.toString() ?? '',
      locationCount: (m['locationCount'] as num?)?.toInt() ?? 0,
      category: (m['category']?.toString() == 'theme')
          ? BundleCategory.theme
          : BundleCategory.city,
      accentColor: _hexToColor(m['accentHex']?.toString() ?? '#888888'),
      icon: _resolveIcon(m['iconKey']?.toString() ?? ''),
    );
  }
}
