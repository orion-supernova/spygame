import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../convex/convex_bootstrap.dart';
import '../storage/identity_storage.dart';

/// Owns the lifecycle of push tokens used by the round-end "Round ended"
/// fan-out. There are two flavours of token, and both are routed through
/// the single `rooms:registerPushTokens` mutation on Convex:
///
///   - **iOS Live Activity APNs token.** Per-activity, rotates each round.
///     ActivityKit emits these via `Activity.pushTokenUpdates`; the
///     `LiveActivityChannel` Swift layer forwards every emission to Dart
///     as `onLiveActivityPushToken`. We forward straight to Convex.
///
///   - **Android FCM token.** Per-device, persists across rounds. Acquired
///     once on game start (or on token rotation). The Dart background
///     isolate handler in `push_messaging.dart` uses the resulting FCM
///     pushes to update the ongoing chronometer notification.
///
/// State kept here is intentionally minimal: the most recent value of each
/// token, and the room code we last registered them against. Re-registers
/// become idempotent on the server (mutation patches by player row).
class PushTokenService {
  PushTokenService._();
  static final PushTokenService instance = PushTokenService._();

  String? _activeRoomCode;
  String? _lastFcmToken;
  String? _lastApnsLiveActivityToken;
  bool _fcmListenerInstalled = false;

  /// Call when the local player joins a room. Acquires (or re-uses) the
  /// FCM token, registers tokens against this room, and starts listening
  /// for FCM token rotations so the next round-end push won't be missed.
  Future<void> bindToRoom(String roomCode) async {
    if (kIsWeb) return;
    _activeRoomCode = roomCode;
    if (Platform.isAndroid) {
      await _ensureFcmListener();
      final token = await _safeFcmToken();
      if (token != null && token != _lastFcmToken) {
        _lastFcmToken = token;
      }
      // Always re-send to Convex — the player row may not have had this
      // token yet (e.g. first round of a new room) even if the value
      // hasn't changed.
      await _sendToConvex(
        roomCode: roomCode,
        fcmToken: _lastFcmToken,
      );
    } else if (Platform.isIOS) {
      // iOS: the Live Activity token will arrive via
      // `onIosLiveActivityToken` once ActivityKit emits it. Push the
      // most recent known value (if any) so the server has SOMETHING
      // before the new activity boots.
      if (_lastApnsLiveActivityToken != null) {
        await _sendToConvex(
          roomCode: roomCode,
          apnsLiveActivityToken: _lastApnsLiveActivityToken,
        );
      } else {
        // Send locale + clear/no-op so the server at least knows the
        // recipient's language for FCM-less pushes (none today, but
        // also useful for future expansion).
        await _sendToConvex(roomCode: roomCode);
      }
    }
  }

  /// Forget the active room. Future token rotations will not be pushed
  /// until [bindToRoom] is called again.
  void unbind() {
    _activeRoomCode = null;
  }

  /// Called by `LiveTimerController` when ActivityKit emits a per-activity
  /// push token. Idempotent — same token is sent at most once per change.
  Future<void> onIosLiveActivityToken({
    required String roomCode,
    required String token,
  }) async {
    if (token.isEmpty) return;
    final isNew = token != _lastApnsLiveActivityToken;
    _lastApnsLiveActivityToken = token;
    // Always honour the room code carried by the callback — it's the room
    // the activity was started for, which is the source of truth.
    if (!isNew && _activeRoomCode == roomCode) return;
    _activeRoomCode = roomCode;
    await _sendToConvex(
      roomCode: roomCode,
      apnsLiveActivityToken: token,
    );
  }

  Future<void> _ensureFcmListener() async {
    if (_fcmListenerInstalled) return;
    _fcmListenerInstalled = true;
    try {
      // Request permission so display-style notifications produced by the
      // background handler can show. On Android 13+ this prompts the
      // POST_NOTIFICATIONS permission; on older versions it's a no-op.
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) async {
          _lastFcmToken = token;
          final room = _activeRoomCode;
          if (room == null) return;
          await _sendToConvex(roomCode: room, fcmToken: token);
        },
        onError: (Object _) {/* ignore: best-effort */},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[push] FCM listener install failed: $e');
    }
  }

  Future<String?> _safeFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[push] getToken failed: $e');
      return null;
    }
  }

  Future<void> _sendToConvex({
    required String roomCode,
    String? apnsLiveActivityToken,
    String? fcmToken,
  }) async {
    if (!ConvexBootstrap.isInitialized) return;
    final args = <String, dynamic>{
      'code': roomCode,
      'clientToken': IdentityStorage.instance.clientToken,
      'locale': _currentLocale(),
    };
    if (apnsLiveActivityToken != null) {
      args['pushTokenApnsLiveActivity'] = apnsLiveActivityToken;
    }
    if (fcmToken != null) {
      args['pushTokenFcm'] = fcmToken;
    }
    try {
      await ConvexBootstrap.client.mutation(
        name: 'rooms:registerPushTokens',
        args: args,
      );
    } catch (e) {
      // The push token register is best-effort: if the server can't be
      // reached, the next bindToRoom / onTokenRefresh / activity start
      // will retry.
      if (kDebugMode) debugPrint('[push] registerPushTokens failed: $e');
    }
  }

  String _currentLocale() {
    final stored = IdentityStorage.instance.languageCode;
    if (stored == 'en' || stored == 'tr') return stored!;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return device == 'tr' ? 'tr' : 'en';
  }
}
