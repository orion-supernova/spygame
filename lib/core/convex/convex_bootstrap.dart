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
    // The web impl of convex_flutter throws "WebSocket not connected" if a
    // subscribe/mutation/query lands before the WS handshake finishes, and
    // ConvexClient.initialize() doesn't await onopen. Cold-start screens
    // (share-link /join/CODE, refreshing /lobby/CODE) subscribe within a
    // frame and lose the race; the home flow doesn't because the user
    // takes seconds to type a name first. Wait briefly for the socket so
    // those screens can talk.
    if (ConvexClient.instance.isConnected) return;
    try {
      await ConvexClient.instance.connectionState
          .firstWhere((s) => s == WebSocketConnectionState.connected)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Don't block launch on a slow handshake — operations will surface
      // their own error if the user is genuinely offline.
    }
  }

  static ConvexClient get client => ConvexClient.instance;
}
