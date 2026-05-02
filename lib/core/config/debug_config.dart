import 'package:flutter/foundation.dart';

/// Min players required to start a game.
///
/// Lowered to 1 in debug builds so the developer can smoke-test the full
/// gameplay flow alone. `kDebugMode` is a compile-time constant — release
/// builds always see `3`, with no env var or runtime toggle to forget.
///
/// The Convex server enforces its own check (gated on `TESTING_MODE` env
/// var on the dev deployment), so prod is safe even if a debug build
/// somehow reaches it.
const int minPlayersToStart = kDebugMode ? 1 : 3;

/// Whether the configured spy count is too high for the current player
/// count. Mirrors the server's TESTING_MODE-aware check in
/// `convex/games.ts` so the Start button reflects what the server will
/// actually accept. In debug, equality is allowed (1 player = 1 spy is
/// fine); in release, the spy count must be strictly less.
bool spyCountExceedsPlayers({
  required int spyCount,
  required int playerCount,
}) {
  return kDebugMode ? spyCount > playerCount : spyCount >= playerCount;
}
