import 'dart:async';
import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../../core/convex/connection_epoch_provider.dart';
import '../../../core/convex/convex_bootstrap.dart';
import '../../../core/convex/convex_client_provider.dart';
import '../../../core/errors/app_exception.dart';
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

  /// Short timeout on one-shot queries: a half-open socket after iOS
  /// suspension would otherwise hang for the package's 30 s default.
  static const _queryTimeout = Duration(seconds: 5);

  Future<List<PickerLocation>> list({
    required String locale,
    required List<String> ownedBundleSlugs,
  }) async {
    await ConvexBootstrap.ensureReady();
    final String raw;
    try {
      raw = await _client
          .query('locations:listForPicker', {
            'locale': locale,
            'ownedBundleSlugs': ownedBundleSlugs,
          })
          .timeout(_queryTimeout);
    } on TimeoutException {
      throw const NetworkException();
    }
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

  /// Live read-only mirror of the host's currently-enabled locations for a
  /// given room. Subscribes to the server query so the read-only sheet
  /// re-renders the moment the host toggles anything.
  Stream<List<PickerLocation>> watchEnabled({
    required String code,
    required String locale,
  }) {
    final controller = StreamController<List<PickerLocation>>.broadcast();
    SubscriptionHandle? handle;

    Future<void> start() async {
      try {
        handle = await _client.subscribe(
          name: 'rooms:enabledLocationsForRoom',
          args: {'code': code, 'locale': locale},
          onUpdate: (raw) {
            if (controller.isClosed) return;
            controller.add(_decodePickerList(raw));
          },
          onError: (message, _) {
            if (controller.isClosed) return;
            controller.addError(message);
          },
        );
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    // ignore: discarded_futures
    start();
    controller.onCancel = () {
      handle?.cancel();
    };
    return controller.stream;
  }

  List<PickerLocation> _decodePickerList(String raw) {
    if (raw.isEmpty) return const [];
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

final locationsPickerRepositoryProvider = Provider<LocationsPickerRepository>((
  ref,
) {
  return LocationsPickerRepository(ref.watch(convexClientProvider));
});

/// Locations the host can pick from for the next game = free pool + every
/// bundle they currently mock-own. Re-fetches if locale or owned set
/// changes; the lobby sheet listens via `ref.watch`.
final locationsForPickerProvider =
    FutureProvider.autoDispose<List<PickerLocation>>((ref) async {
      // Refetch when the socket reconnects (also clears a sticky error state).
      ref.watch(connectionEpochProvider);
      final repo = ref.watch(locationsPickerRepositoryProvider);
      final locale = ref.watch(localeProvider).languageCode;
      final owned = ref.watch(ownedBundlesProvider).toList();
      return repo.list(locale: locale, ownedBundleSlugs: owned);
    });

/// Live stream of currently-enabled locations for a room. Backs the
/// non-host read-only sheet so toggles by the host are reflected instantly.
/// Keyed by room code; locale is read from `localeProvider`.
final enabledLocationsForRoomProvider = StreamProvider.autoDispose
    .family<List<PickerLocation>, String>((ref, code) {
      final repo = ref.watch(locationsPickerRepositoryProvider);
      final locale = ref.watch(localeProvider).languageCode;
      return repo.watchEnabled(code: code, locale: locale);
    });
