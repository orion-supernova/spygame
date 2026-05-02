import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/convex/convex_bootstrap.dart';
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

  runApp(const ProviderScope(child: WhereAmIApp()));
}
