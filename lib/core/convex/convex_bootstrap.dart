import 'package:convex_flutter/convex_flutter.dart';

import '../config/convex_config.dart';

/// Initializes the Convex client singleton at startup. The deployment URL is
/// passed via --dart-define=CONVEX_URL. If absent, we leave the client
/// uninitialized so the app can launch and surface a clear configuration
/// error in the welcome screen rather than crashing on splash.
class ConvexBootstrap {
  ConvexBootstrap._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!AppConvexConfig.isConfigured) return;
    await ConvexClient.initialize(
      ConvexConfig(deploymentUrl: AppConvexConfig.deploymentUrl),
    );
    _initialized = true;
  }

  static ConvexClient get client => ConvexClient.instance;
}
