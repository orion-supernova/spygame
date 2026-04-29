import 'dart:async';
import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';

import '../../../core/storage/identity_storage.dart';
import '../domain/game_repository.dart';
import '../domain/role.dart';

class ConvexGameRepository implements GameRepository {
  ConvexGameRepository(this._client, this._identity);
  final ConvexClient _client;
  final IdentityStorage _identity;

  @override
  Stream<Role?> watchMyRole(String roundId, String locale) {
    final controller = StreamController<Role?>.broadcast();
    SubscriptionHandle? handle;
    Future<void> start() async {
      try {
        handle = await _client.subscribe(
          name: 'games:getMyRole',
          args: {
            'roundId': roundId,
            'clientToken': _identity.clientToken,
            'locale': locale,
          },
          onUpdate: (raw) {
            if (controller.isClosed) return;
            final decoded = _decode(raw);
            if (decoded == null) {
              controller.add(null);
              return;
            }
            final m = _asMap(decoded);
            if (m == null) {
              controller.add(null);
              return;
            }
            final roleStr = m['role']?.toString();
            final isSpy = roleStr == 'spy';
            final roundIndex = _asInt(m['roundIndex'], 0);
            if (isSpy) {
              controller.add(Role.spy(roundIndex: roundIndex));
              return;
            }
            final loc = m['location'];
            final locName = (loc is Map ? loc['name']?.toString() : null) ??
                'Unknown';
            controller.add(Role.civilian(
              label: roleStr ?? 'Player',
              locationName: locName,
              roundIndex: roundIndex,
            ));
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

  @override
  Stream<LocationsBoard> watchLocations(String code, String locale) {
    final controller = StreamController<LocationsBoard>.broadcast();
    SubscriptionHandle? handle;
    Future<void> start() async {
      try {
        handle = await _client.subscribe(
          name: 'games:watchLocations',
          args: {'code': code, 'locale': locale},
          onUpdate: (raw) {
            if (controller.isClosed) return;
            final decoded = _decode(raw);
            final m = _asMap(decoded);
            if (m == null) {
              controller.add(const LocationsBoard(
                locations: [],
                playedIds: {},
              ));
              return;
            }
            final locsRaw = m['locations'];
            final playedRaw = m['playedIds'];
            final locs = <LocationItem>[];
            if (locsRaw is List) {
              for (final l in locsRaw) {
                if (l is Map) {
                  locs.add(LocationItem(
                    id: l['_id']?.toString() ?? '',
                    name: l['name']?.toString() ?? '',
                  ));
                }
              }
            }
            final played = <String>{};
            if (playedRaw is List) {
              for (final id in playedRaw) {
                played.add(id.toString());
              }
            }
            controller.add(
              LocationsBoard(locations: locs, playedIds: played),
            );
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

  @override
  Future<void> endRoundIfDue({
    required String roundId,
    required int expectedEndsAtMs,
  }) async {
    try {
      await _client.mutation(
        name: 'games:endRoundIfDue',
        args: {
          'roundId': roundId,
          'expectedEndsAtMs': expectedEndsAtMs,
        },
      );
    } catch (_) {/* idempotent — silent on failure */}
  }

  Object? _decode(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map<String, dynamic>(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
    return null;
  }

  int _asInt(Object? v, int fallback) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
