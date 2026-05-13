import 'package:convex_flutter/convex_flutter.dart';

import '../config/convex_config.dart';

/// Two-phase bootstrap for the Convex client singleton.
///
///  1. [ensureInitialized] runs `ConvexClient.initialize()` so the singleton
///     exists. Fast (~100 ms — dylib load + listener setup). `main()` awaits
///     this so anything reading `ConvexClient.instance` afterwards is safe.
///  2. [ensureReady] additionally waits, best-effort with a 5 s soft
///     timeout, for the WebSocket handshake to complete. Data-layer
///     operations await this before firing mutations/subscribes; deep-link
///     routes that mount before the socket connects simply pause their
///     first request instead of crashing.
///
/// The deployment URL is passed via `--dart-define=CONVEX_URL`. If absent
/// (and no default is set) the client is left uninitialized so the welcome
/// screen can show a configuration error instead of crashing on splash.
class ConvexBootstrap {
  ConvexBootstrap._();

  static Future<void>? _initFuture;
  static Future<void>? _readyFuture;
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Creates the [ConvexClient] singleton. Idempotent and cached. Returns
  /// once the singleton is constructed (the WebSocket may still be
  /// connecting in the background — use [ensureReady] for that).
  static Future<void> ensureInitialized() {
    return _initFuture ??= _initialize();
  }

  static Future<void> _initialize() async {
    if (!AppConvexConfig.isConfigured) return;
    await ConvexClient.initialize(
      const ConvexConfig(deploymentUrl: AppConvexConfig.deploymentUrl),
    );
    _initialized = true;
  }

  /// Awaits singleton initialization AND best-effort WebSocket connection
  /// (5 s soft timeout — never throws). Idempotent and cached.
  static Future<void> ensureReady() {
    return _readyFuture ??= _waitReady();
  }

  static Future<void> _waitReady() async {
    await ensureInitialized();
    if (!_initialized) return;
    if (ConvexClient.instance.isConnected) return;
    try {
      await ConvexClient.instance.connectionState
          .firstWhere((s) => s == WebSocketConnectionState.connected)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline-tolerant: operations surface their own error if the user is
      // genuinely offline.
    }
  }

  static ConvexClient get client => ConvexClient.instance;
}
