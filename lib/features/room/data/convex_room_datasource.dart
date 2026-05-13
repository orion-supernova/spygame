import 'dart:async';
import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';

import '../../../core/convex/convex_bootstrap.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/identity_storage.dart';
import '../domain/room.dart';
import '../domain/room_repository.dart';
import 'room_dto.dart';

class ConvexRoomRepository implements RoomRepository {
  ConvexRoomRepository(this._client, this._identity);

  final ConvexClient _client;
  final IdentityStorage _identity;

  static const _interactiveMutationTimeout = Duration(seconds: 5);

  @override
  Future<String> createRoom({required String displayName}) async {
    try {
      await ConvexBootstrap.ensureReady();
      final raw = await _client.mutation(
        name: 'rooms:createRoom',
        args: {
          'displayName': displayName,
          'clientToken': _identity.clientToken,
        },
      ).timeout(_interactiveMutationTimeout);
      final result = _decode(raw);
      final code = (result is Map ? result['code'] : null)?.toString();
      if (code == null || code.isEmpty) {
        throw const UnknownException('Server did not return a room code.');
      }
      return code.toUpperCase();
    } on TimeoutException {
      throw const NetworkException();
    } on AppException {
      rethrow;
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<String> joinRoom({
    required String code,
    required String displayName,
  }) async {
    try {
      await ConvexBootstrap.ensureReady();
      final raw = await _client.mutation(
        name: 'rooms:joinRoom',
        args: {
          'code': code,
          'displayName': displayName,
          'clientToken': _identity.clientToken,
        },
      ).timeout(_interactiveMutationTimeout);
      final result = _decode(raw);
      final returned =
          (result is Map ? result['code'] : null)?.toString() ?? code;
      return returned.toUpperCase();
    } on TimeoutException {
      throw const NetworkException();
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> leaveRoom({required String code}) async {
    try {
      await ConvexBootstrap.ensureReady();
      await _client.mutation(
        name: 'rooms:leaveRoom',
        args: {
          'code': code,
          'clientToken': _identity.clientToken,
        },
      );
    } catch (_) {/* fire-and-forget */}
  }

  @override
  Future<void> setReady({
    required String code,
    required bool ready,
  }) async {
    try {
      await ConvexBootstrap.ensureReady();
      await _client.mutation(
        name: 'rooms:setReady',
        args: {
          'code': code,
          'clientToken': _identity.clientToken,
          'ready': ready,
        },
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> updateConfig({
    required String code,
    required GameConfig config,
  }) async {
    try {
      await ConvexBootstrap.ensureReady();
      await _client.mutation(
        name: 'rooms:updateConfig',
        args: {
          'code': code,
          'clientToken': _identity.clientToken,
          'spyCount': config.spyCount,
          'roundMinutes': config.roundMinutes,
          'roundCount': config.roundCount,
        },
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> setDisabledLocations({
    required String code,
    required List<String> disabledLocationIds,
  }) async {
    try {
      await ConvexBootstrap.ensureReady();
      await _client.mutation(
        name: 'rooms:setDisabledLocations',
        args: {
          'code': code,
          'clientToken': _identity.clientToken,
          'disabledLocationIds': disabledLocationIds,
        },
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> setHostOwnedBundleSlugs({
    required String code,
    required List<String> slugs,
  }) async {
    try {
      await ConvexBootstrap.ensureReady();
      await _client.mutation(
        name: 'rooms:setHostOwnedBundleSlugs',
        args: {
          'code': code,
          'clientToken': _identity.clientToken,
          'slugs': slugs,
        },
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> heartbeat({required String code}) async {
    try {
      await ConvexBootstrap.ensureReady();
      await _client.mutation(
        name: 'rooms:heartbeat',
        args: {
          'code': code,
          'clientToken': _identity.clientToken,
        },
      );
    } catch (_) {/* tolerate */}
  }

  @override
  Future<void> startGame({
    required String code,
    required List<String> ownedBundleSlugs,
  }) async {
    try {
      await ConvexBootstrap.ensureReady();
      await _client.mutation(
        name: 'games:startGame',
        args: {
          'code': code,
          'clientToken': _identity.clientToken,
          'ownedBundleSlugs': ownedBundleSlugs,
        },
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> endRoundManual({required String code}) async {
    try {
      await ConvexBootstrap.ensureReady();
      await _client.mutation(
        name: 'games:endRoundManual',
        args: {
          'code': code,
          'clientToken': _identity.clientToken,
        },
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Stream<Room?> watchRoom(String code) {
    final controller = StreamController<Room?>.broadcast();
    SubscriptionHandle? handle;

    Future<void> start() async {
      try {
        await ConvexBootstrap.ensureReady();
        handle = await _client.subscribe(
          name: 'rooms:watchRoom',
          args: {'code': code},
          onUpdate: (raw) {
            if (controller.isClosed) return;
            final decoded = _decode(raw);
            if (decoded == null) {
              controller.add(null);
              return;
            }
            controller.add(RoomMapper.fromJson(_asMap(decoded)));
          },
          onError: (message, _) {
            if (controller.isClosed) return;
            controller.addError(_mapError(message));
          },
        );
      } catch (e) {
        if (!controller.isClosed) controller.addError(_mapError(e));
      }
    }

    // ignore: discarded_futures
    start();
    controller.onCancel = () {
      handle?.cancel();
    };
    return controller.stream;
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

  AppException _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('No room with that code')) {
      return const RoomNotFoundException();
    }
    if (msg.contains('full')) return const RoomFullException();
    if (msg.toLowerCase().contains('only the host') ||
        msg.toLowerCase().contains('not authorized')) {
      return const NotAuthorizedException(
        'Only the host can do that.',
      );
    }
    if (msg.toLowerCase().contains('socket') ||
        msg.toLowerCase().contains('network') ||
        msg.toLowerCase().contains('timeout') ||
        msg.toLowerCase().contains('connection')) {
      return const NetworkException();
    }
    // Never surface raw server/exception text to users — those strings can
    // leak implementation details (e.g. "WebSocket not connected"). The
    // presentation layer maps this to the localized fallback.
    return const UnknownException();
  }
}
