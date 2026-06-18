import 'dev_mode.dart';

/// Min players required to start a game.
///
/// Lowered to 1 whenever dev tools are available — i.e. any debug build, or a
/// release build where dev mode was unlocked at runtime via the hidden 10-tap
/// version gesture + server-verified code (see [devToolsEnabled] /
/// `welcome_screen.dart`). Release builds without dev mode always see `3`.
///
/// The Convex server enforces its own check (gated on `TESTING_MODE` env var),
/// so prod is safe even if a client somehow asks to start solo.
int get minPlayersToStart => devToolsEnabled ? 1 : 3;

/// Whether the configured spy count is too high for the current player
/// count. Mirrors the server's TESTING_MODE-aware check in
/// `convex/games.ts` so the Start button reflects what the server will
/// actually accept. With dev tools available, equality is allowed (1 player =
/// 1 spy is fine); otherwise the spy count must be strictly less.
bool spyCountExceedsPlayers({
  required int spyCount,
  required int playerCount,
}) {
  return devToolsEnabled ? spyCount > playerCount : spyCount >= playerCount;
}
