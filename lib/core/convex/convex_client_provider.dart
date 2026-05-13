import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/convex_config.dart';
import 'convex_bootstrap.dart';

/// Hands out the Convex client singleton. The instance always exists once
/// [ConvexBootstrap.ensureReady] has been called (which `main()` triggers
/// fire-and-forget). Callers that need a live socket must `await`
/// `ConvexBootstrap.ensureReady()` themselves before issuing operations —
/// the repositories already do this.
final convexClientProvider = Provider<ConvexClient>((ref) {
  return ConvexBootstrap.client;
});

/// True iff a CONVEX_URL was provided at build time. Independent of socket
/// state — this only answers "did the build include a deployment URL?",
/// which is what the welcome screen's configuration banner cares about.
final convexConfiguredProvider = Provider<bool>((ref) {
  return AppConvexConfig.isConfigured;
});
