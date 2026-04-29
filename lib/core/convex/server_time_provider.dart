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

  @override
  int build() => 0;

  Future<void> refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final completer = Completer<void>();
    _refreshing = completer;
    try {
      final client = ref.read(convexClientProvider);
      final t0 = DateTime.now().millisecondsSinceEpoch;
      final raw = await client.query('games:serverNow', const {});
      final t1 = DateTime.now().millisecondsSinceEpoch;
      final serverMs = _coerceMs(raw);
      final rtt = (t1 - t0) ~/ 2;
      state = serverMs - (t0 + rtt);
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
  } catch (_) {/* fall through */}
  return int.tryParse(raw) ?? DateTime.now().millisecondsSinceEpoch;
}

final serverTimeOffsetProvider =
    NotifierProvider<ServerTimeOffsetController, int>(
  ServerTimeOffsetController.new,
);
