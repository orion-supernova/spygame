import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/convex/convex_bootstrap.dart';
import 'core/notifications/push_messaging.dart';
import 'core/notifications/round_end_notifier.dart';
import 'core/storage/identity_storage.dart';
import 'features/marketplace/data/owned_bundles_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Draw behind the system status and navigation bars so the app's ink
  // background extends through the top notch and bottom home-indicator area
  // instead of leaving an opaque black strip.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  await IdentityStorage.instance.init();
  await OwnedBundlesStorage.instance.init();
  await RoundEndNotifier.instance.init();
  await ConvexBootstrap.initialize();
  await _initFirebaseMessaging();

  runApp(const ProviderScope(child: WhereAmIApp()));
}

/// Wires up Firebase Cloud Messaging on Android. Skipped on iOS — the
/// "widget" surface there is the Live Activity, which is updated by
/// per-activity APNs push tokens registered via [LiveActivityChannel],
/// not by FCM.
///
/// Failures here are non-fatal: missing google-services.json, unsupported
/// platform, or no network at startup all result in a debug log and the
/// app continues without push. The chronometer notification still ticks
/// down locally and the Convex subscription will still update on
/// foreground.
Future<void> _initFirebaseMessaging() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(handleForegroundRoundEndedMessage);
  } catch (e) {
    if (kDebugMode) debugPrint('[push] Firebase init skipped: $e');
  }
}
