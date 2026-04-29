import 'package:meta/meta.dart';

enum RoomStatus { lobby, inGame, ended }

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
    required this.currentRoundIndex,
    required this.totalRounds,
  });

  final String id;
  final String status;
  final int currentRoundIndex;
  final int totalRounds;
}

@immutable
class Room {
  const Room({
    required this.id,
    required this.code,
    required this.status,
    required this.ownerToken,
    required this.config,
    required this.players,
    required this.currentGame,
    required this.currentRound,
  });

  final String id;
  final String code;
  final RoomStatus status;
  final String ownerToken;
  final GameConfig config;
  final List<Player> players;
  final GameSnapshot? currentGame;
  final RoundSnapshot? currentRound;

  Player? playerFor(String clientToken) =>
      players.where((p) => p.clientToken == clientToken).firstOrNull;

  bool isOwner(String clientToken) => ownerToken == clientToken;

  bool get allReady =>
      players.isNotEmpty && players.every((p) => p.isReady);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
