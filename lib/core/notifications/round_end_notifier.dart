import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules a local notification at the absolute end-of-round time so the
/// user gets pinged even if the app is backgrounded or the device is locked.
///
/// We use *inexact* scheduling on Android so the app does not require the
/// SCHEDULE_EXACT_ALARM permission (Android 14+). ±1 minute is acceptable
/// for a party game.
class RoundEndNotifier {
  RoundEndNotifier._();
  static final RoundEndNotifier instance = RoundEndNotifier._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'whereami.round';
  static const _channelName = 'Round timer';
  static const _channelDesc = 'Notifies when a round ends.';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
    );
    _initialized = true;
  }

  Future<bool> requestPermissionIfNeeded() async {
    if (kIsWeb) return false;
    if (Platform.isIOS || Platform.isMacOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? true;
      return granted;
    }
    return false;
  }

  Future<void> scheduleAt({
    required int notificationId,
    required int endsAtLocalMs,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    final delayMs = endsAtLocalMs - DateTime.now().millisecondsSinceEpoch;
    if (delayMs <= 0) return;

    final scheduled = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local,
      endsAtLocalMs,
    );

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);
  Future<void> cancelAll() => _plugin.cancelAll();
}
