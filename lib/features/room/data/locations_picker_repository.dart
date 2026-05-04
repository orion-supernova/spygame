import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../../core/convex/convex_client_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../marketplace/data/marketplace_providers.dart';

/// One row in the lobby's locations picker. `bundleSlug` is null for the
/// free pool; otherwise the slug points at a server-backed bundle whose
/// title the client looks up locally via `bundlesProvider`.
@immutable
class PickerLocation {
  const PickerLocation({
    required this.id,
    required this.name,
    required this.bundleSlug,
  });

  final String id;
  final String name;
  final String? bundleSlug;
}

class LocationsPickerRepository {
  LocationsPickerRepository(this._client);

  final ConvexClient _client;

  Future<List<PickerLocation>> list({
    required String locale,
    required List<String> ownedBundleSlugs,
  }) async {
    final raw = await _client.query('locations:listForPicker', {
      'locale': locale,
      'ownedBundleSlugs': ownedBundleSlugs,
    });
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<Object?, Object?>>().map((m) {
      final slug = m['bundleSlug']?.toString();
      return PickerLocation(
        id: m['_id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        bundleSlug: (slug == null || slug.isEmpty) ? null : slug,
      );
    }).toList();
  }
}

final locationsPickerRepositoryProvider =
    Provider<LocationsPickerRepository>((ref) {
  return LocationsPickerRepository(ref.watch(convexClientProvider));
});

/// Locations the host can pick from for the next game = free pool + every
/// bundle they currently mock-own. Re-fetches if locale or owned set
/// changes; the lobby sheet listens via `ref.watch`.
final locationsForPickerProvider =
    FutureProvider.autoDispose<List<PickerLocation>>((ref) async {
  final repo = ref.watch(locationsPickerRepositoryProvider);
  final locale = ref.watch(localeProvider).languageCode;
  final owned = ref.watch(ownedBundlesProvider).toList();
  return repo.list(locale: locale, ownedBundleSlugs: owned);
});
