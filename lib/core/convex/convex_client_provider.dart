import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/convex_config.dart';
import 'convex_bootstrap.dart';

final convexClientProvider = Provider<ConvexClient>((ref) {
  if (!ConvexBootstrap.isInitialized) {
    throw StateError(
      'Convex client not initialized — set --dart-define=CONVEX_URL=...',
    );
  }
  return ConvexBootstrap.client;
});

final convexConfiguredProvider = Provider<bool>((ref) {
  return AppConvexConfig.isConfigured && ConvexBootstrap.isInitialized;
});
