import 'package:meta/meta.dart';

enum RoomStatus { lobby, inGame, ended }

/// Sub-state of a game when `RoomStatus.inGame`. Drives which screen the
/// game UI renders (round in progress vs intermission vs 3s countdown).
enum GamePhase { playing, between, starting, ended }

@immutable
class GameConfig {
  const GameConfig({
    required this.spyCount,
    required this.roundMinutes,
    required this.roundCount,
  });

  final int spyCount;
  final int roundMinutes;
  final int roundCount;

  GameConfig copyWith({int? spyCount, int? roundMinutes, int? roundCount}) =>
      GameConfig(
        spyCount: spyCount ?? this.spyCount,
        roundMinutes: roundMinutes ?? this.roundMinutes,
        roundCount: roundCount ?? this.roundCount,
      );

  @override
  bool operator ==(Object other) =>
      other is GameConfig &&
      other.spyCount == spyCount &&
      other.roundMinutes == roundMinutes &&
      other.roundCount == roundCount;

  @override
  int get hashCode => Object.hash(spyCount, roundMinutes, roundCount);
}

@immutable
class Player {
  const Player({
    required this.id,
    required this.clientToken,
    required this.displayName,
    required this.isReady,
    required this.isOwner,
    required this.joinedAt,
  });

  final String id;
  final String clientToken;
  final String displayName;
  final bool isReady;
  final bool isOwner;
  final int joinedAt;
}

@immutable
class RoundSnapshot {
  const RoundSnapshot({
    required this.id,
    required this.index,
    required this.startedAtMs,
    required this.endsAtMs,
    required this.status,
    required this.endedReason,
  });

  final String id;
  final int index;
  final int startedAtMs;
  final int endsAtMs;
  final String status; // 'active' | 'ended'
  final String? endedReason;

  bool get isActive => status == 'active';
}

@immutable
class GameSnapshot {
  const GameSnapshot({
    required this.id,
    required this.status,
    required this.phase,
    required this.nextRoundStartsAtMs,
    required this.currentRoundIndex,
    required this.totalRounds,
    this.lastSpyRevealRoundIndex,
    this.lastSpyClientToken,
  });

  final String id;
  final String status;
  final GamePhase phase;
  final int? nextRoundStartsAtMs;
  final int currentRoundIndex;
  final int totalRounds;
  final int? lastSpyRevealRoundIndex;
  final String? lastSpyClientToken;
}

@immutable
class Room {
  const Room({
    required this.id,
    required this.code,
    required this.serverNowMs,
    required this.receivedAtLocalMs,
    required this.status,
    required this.ownerToken,
    required this.config,
    required this.disabledLocationIds,
    required this.hostOwnedBundleSlugs,
    required this.activePackSlugs,
    required this.freePackActive,
    required this.enabledLocationCount,
    required this.totalLocationCount,
    required this.activeThemeSlug,
    required this.players,
    required this.currentGame,
    required this.currentRound,
  });

  final String id;
  final String code;
  final int serverNowMs;
  final int receivedAtLocalMs;
  final RoomStatus status;
  final String ownerToken;
  final GameConfig config;
  /// Location IDs the host has blacklisted for the next game from this
  /// room. Persists across games. Snapshotted onto the game row at
  /// startGame so mid-game edits don't change the running pool.
  final Set<String> disabledLocationIds;
  /// Bundle slugs the current host claims to own, published by the host
  /// client so non-hosts can render the same "active packs" chips. Empty
  /// until the host's lobby listener pushes; cleared on ownership transfer.
  final Set<String> hostOwnedBundleSlugs;
  /// Server-derived set of bundle slugs that have at least one enabled
  /// location given `hostOwnedBundleSlugs` and `disabledLocationIds`. Read
  /// directly by the lobby chip strip — clients don't need to recompute.
  final Set<String> activePackSlugs;
  /// True if at least one free location is enabled. Drives the implicit
  /// "Free" chip in the lobby.
  final bool freePackActive;
  /// Server-derived count of locations currently enabled in the room's
  /// pool (free + host-owned packs minus disabled). Updates live on every
  /// host toggle so non-hosts see the change without opening anything.
  final int enabledLocationCount;
  /// Total locations in the pool (free + host-owned packs, ignoring the
  /// disabled list). Pairs with `enabledLocationCount` for the "X / Y"
  /// progress badge.
  final int totalLocationCount;
  /// Slug of the theme pack the host has selected to skin the room, or null
  /// for the default noir look. Synced to all players so the whole table
  /// shares the visual theme for the duration it's enabled.
  final String? activeThemeSlug;
  final List<Player> players;
  final GameSnapshot? currentGame;
  final RoundSnapshot? currentRound;

  Player? playerFor(String clientToken) =>
      players.where((p) => p.clientToken == clientToken).firstOrNull;

  bool isOwner(String clientToken) => ownerToken == clientToken;

  bool get allReady => players.isNotEmpty && players.every((p) => p.isReady);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
