import 'dart:io' show Platform;
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'round_end_notifier.dart';

/// Handles `round_ended` FCM data messages on Android. The whole point of
/// this file is to update the ongoing chronometer notification when the
/// round ends server-side while the app is fully backgrounded — at that
/// point the Convex websocket is suspended, so the app would otherwise
/// learn about the round-end only on next foreground.
///
/// FCM data-only messages (no `notification` field, Android priority HIGH)
/// wake either the foreground listener (`onMessage`) or, when the app is
/// killed/backgrounded, the dedicated background isolate. The handler is
/// the same shape in both cases — it just dismisses the running
/// chronometer (id 999_999) and posts a fresh "Round ended" alert.
///
/// **Background isolate caveat.** `onBackgroundMessage` runs in a separate
/// isolate. The `RoundEndNotifier` singleton in the main isolate does not
/// carry over, and `flutter_local_notifications` must be re-initialized
/// here. This file deliberately does not reach into `RoundEndNotifier`
/// state and instead constructs a fresh plugin instance.
///
/// Known gap (acceptable for v1): aggressive task killers on some Chinese
/// OEMs (Xiaomi, Huawei, Oppo) can prevent the background isolate from
/// running at all.

const String _alertChannelId = 'whereami.round';
const String _alertChannelName = 'Round timer';
const String _alertChannelDesc = 'Notifies when a round ends.';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized in this isolate, e.g. on a hot rebuild during dev.
  }
  await _handleRoundEnded(message);
}

Future<void> _handleRoundEnded(RemoteMessage message) async {
  if (message.data['type'] != 'round_ended') return;
  if (!Platform.isAndroid) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  // Cancel the ongoing countdown notification — its chronometer is now
  // either at 0:00 (timer expiry) or stuck on a stale time (early end).
  await plugin.cancel(RoundEndNotifier.liveTimerNotificationId);

  final title = (message.data['title'] as String?)?.trim().isNotEmpty == true
      ? message.data['title'] as String
      : 'Round ended';
  final body = (message.data['body'] as String?)?.trim().isNotEmpty == true
      ? message.data['body'] as String
      : 'Open the app to see what happened.';
  final notificationId = _notificationIdFor(message);

  await plugin.show(
    notificationId,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _alertChannelId,
        _alertChannelName,
        channelDescription: _alertChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      ),
    ),
  );
}

/// Stable per-round id so duplicate FCM deliveries don't pile up multiple
/// "Round ended" cards. Falls back to a random-ish hash when the payload
/// doesn't carry a roundId (shouldn't happen — the server always sends it).
int _notificationIdFor(RemoteMessage message) {
  final roundId = message.data['roundId'];
  if (roundId is String && roundId.isNotEmpty) {
    return 100_000 + (roundId.hashCode & 0x3FFFFF);
  }
  return 100_000 + (message.messageId?.hashCode ?? 0) & 0x3FFFFF;
}

/// Foreground (and background, when this is wired from `onMessage`) entry
/// point. Same logic as the background handler — kept in one place.
@pragma('vm:entry-point')
Future<void> handleForegroundRoundEndedMessage(RemoteMessage message) async {
  await _handleRoundEnded(message);
  if (kDebugMode) {
    debugPrint('[push] foreground round_ended handled: ${message.messageId}');
  }
}
