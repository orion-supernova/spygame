import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/convex/convex_bootstrap.dart';
import 'core/notifications/round_end_notifier.dart';
import 'core/storage/identity_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await IdentityStorage.instance.init();
  await RoundEndNotifier.instance.init();
  await ConvexBootstrap.initialize();

  runApp(const ProviderScope(child: WhereAmIApp()));
}
