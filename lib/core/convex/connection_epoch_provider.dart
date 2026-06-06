import 'dart:async';

import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'convex_bootstrap.dart';

/// Monotonic counter bumped every time the WebSocket (re)enters the
/// `connected` state. One-shot FutureProviders `ref.watch` this so they
/// auto-refetch after a suspension-induced reconnect — which also clears a
/// sticky error AsyncValue without any user interaction.
///
/// Bumps only on the rising edge *into* connected (the state enum is just
/// {connecting, connected}), so a healthy resume — where the socket never
/// dropped — causes zero bumps and therefore zero duplicate fetches.
class ConnectionEpoch extends Notifier<int> {
  @override
  int build() {
    if (!ConvexBootstrap.isInitialized) return 0;
    final client = ConvexClient.instance;
    var lastConnected = client.isConnected;
    final StreamSubscription<WebSocketConnectionState> sub = client
        .connectionState
        .listen((s) {
          final nowConnected = s == WebSocketConnectionState.connected;
          if (nowConnected && !lastConnected) state = state + 1;
          lastConnected = nowConnected;
        });
    ref.onDispose(sub.cancel);
    return 0;
  }
}

final connectionEpochProvider = NotifierProvider<ConnectionEpoch, int>(
  ConnectionEpoch.new,
);
