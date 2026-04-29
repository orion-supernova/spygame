import 'dart:async';
import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/identity_storage.dart';
import '../domain/room.dart';
import '../domain/room_repository.dart';
import 'room_dto.dart';

class ConvexRoomRepository implements RoomRepository {
  ConvexRoomRepository(this._client, this._identity);

  final ConvexClient _client;
  final IdentityStorage _identity;

  @override
  Future<String> createRoom({required String displayName}) async {
    try {
      final raw = await _client.mutation(
        name: 'rooms:createRoom',
        args: {
          'displayName': displayName,
          'clientToken': _identity.clientToken,
        },
      );
      final result = _decode(raw);
      final code = (result is Map ? result['code'] : null)?.toString();
      if (code == null || code.isEmpty) {
        throw const UnknownException('Server did not return a room code.');
      }
      return code.toUpperCase();
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
      final raw = await _client.mutation(
        name: 'rooms:joinRoom',
        args: {
          'code': code,
          'displayName': displayName,
          'clientToken': _identity.clientToken,
        },
      );
      final result = _decode(raw);
      final returned =
          (result is Map ? result['code'] : null)?.toString() ?? code;
      return returned.toUpperCase();
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> leaveRoom({required String code}) async {
    try {
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
  Future<void> heartbeat({required String code}) async {
    try {
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
  Future<void> startGame({required String code}) async {
    try {
      await _client.mutation(
        name: 'games:startGame',
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
  Future<void> endRoundManual({required String code}) async {
    try {
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
        msg.toLowerCase().contains('network')) {
      return const NetworkException();
    }
    return UnknownException(_cleanMessage(msg));
  }

  String _cleanMessage(String raw) {
    final match = RegExp(r'(?:ConvexError|Error):\s*([^\n]+)').firstMatch(raw);
    return match?.group(1)?.trim() ?? raw.split('\n').first;
  }
}
