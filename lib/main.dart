import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/convex/convex_bootstrap.dart';
import 'core/iap/revenuecat_bootstrap.dart';
import 'core/notifications/push_messaging.dart';
import 'core/notifications/round_end_notifier.dart';
import 'core/storage/identity_storage.dart';

Future<void> main() async {
  // Use clean `/join/CODE` URLs on web so shared links route into the app
  // instead of bouncing to Welcome. No-op on iOS/Android.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Fire-and-forget — these don't gate the first frame. Draws behind the
  // system status/nav bars so the app's ink background extends through the
  // notch + home-indicator area instead of leaving an opaque black strip.
  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
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

  // Widgets and providers read IdentityStorage fields synchronously on the
  // first build (HomeScreen codename field, locale provider, RevenueCat
  // appUserID), so this one stays awaited.
  await IdentityStorage.instance.init();

  // Create the Convex singleton so providers reading ConvexClient.instance
  // (room/game repositories, etc.) don't throw on first build. Fast — just
  // dylib load + WS listener registration; the slow handshake wait happens
  // in the background via ensureReady() which data-layer operations await.
  await ConvexBootstrap.ensureInitialized();

  // Everything else bootstraps in parallel with the first frame.
  unawaited(RevenueCatBootstrap.initialize());
  unawaited(RoundEndNotifier.instance.init());
  unawaited(ConvexBootstrap.ensureReady());
  unawaited(_initFirebaseMessaging());

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
