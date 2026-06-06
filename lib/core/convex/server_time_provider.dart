import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'convex_client_provider.dart';

/// Holds the offset between the server clock and the local device clock so
/// that `endsAtMs` (server-stamped) can be rendered accurately on the
/// client even if the device clock drifts. Recomputed on every app resume.
///
/// `serverNowMs = DateTime.now().millisecondsSinceEpoch + offsetMs`.
class ServerTimeOffsetController extends Notifier<int> {
  Completer<void>? _refreshing;
  bool _hasSynced = false;
  int _lastRefreshStartedAtMs = 0;

  @override
  int build() => 0;

  void observeServerNow(int serverNowMs, {int? receivedAtLocalMs}) {
    if (serverNowMs <= 0) return;
    final localMs = receivedAtLocalMs ?? DateTime.now().millisecondsSinceEpoch;

    // `serverNowMs` came from a live query, not a request/response clock
    // sample. By the time it reaches this device it can be seconds old, so it
    // must not directly become the offset. Treat it only as a nudge to take a
    // proper midpoint sample from games:serverNow.
    if (_hasSynced && localMs - _lastRefreshStartedAtMs < 10_000) return;
    // ignore: discarded_futures
    refresh();
  }

  /// Re-samples the server clock. Doubles as the post-resume reconnect
  /// probe: after iOS suspension the WebSocket can be half-open while the
  /// client still reads "connected", and the only fast way to surface that
  /// is to write to the socket. The short per-attempt timeout (instead of
  /// the package's 30 s default) plus retries means a dead socket is
  /// detected — and the Rust SDK kicked into reconnecting — within seconds,
  /// after which a retry lands on the fresh socket.
  Future<void> refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final completer = Completer<void>();
    _refreshing = completer;
    try {
      final client = ref.read(convexClientProvider);
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final t0 = DateTime.now().millisecondsSinceEpoch;
          _lastRefreshStartedAtMs = t0;
          final raw = await client
              .mutation(
                name: 'games:serverNow',
                args: const <String, dynamic>{},
              )
              .timeout(const Duration(seconds: 5));
          final t1 = DateTime.now().millisecondsSinceEpoch;
          final serverMs = _coerceMs(raw);
          final rtt = (t1 - t0) ~/ 2;
          state = serverMs - (t0 + rtt);
          _hasSynced = true;
          return;
        } on TimeoutException {
          // Dead/half-open socket — the write itself nudges the SDK toward
          // reconnecting, so the next attempt often succeeds.
          continue;
        }
      }
    } catch (_) {
      // Leave previous offset in place.
    } finally {
      completer.complete();
      _refreshing = null;
    }
  }

  int toServerMs(int localMs) => localMs + state;
  int toLocalMs(int serverMs) => serverMs - state;
  int get nowAsServerMs => DateTime.now().millisecondsSinceEpoch + state;
}

int _coerceMs(String raw) {
  if (raw.isEmpty) return DateTime.now().millisecondsSinceEpoch;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is int) return decoded;
    if (decoded is double) return decoded.round();
    if (decoded is String) {
      return int.tryParse(decoded) ?? DateTime.now().millisecondsSinceEpoch;
    }
    if (decoded is Map && decoded['ms'] != null) {
      final v = decoded['ms'];
      if (v is int) return v;
      if (v is double) return v.round();
    }
  } catch (_) {
    /* fall through */
  }
  return int.tryParse(raw) ?? DateTime.now().millisecondsSinceEpoch;
}

final serverTimeOffsetProvider =
    NotifierProvider<ServerTimeOffsetController, int>(
      ServerTimeOffsetController.new,
    );
