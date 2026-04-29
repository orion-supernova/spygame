import '../domain/room.dart';

/// Decodes the JSON-ish maps that come back from Convex into our domain
/// types. We hand-roll this because there's no Convex Dart codegen — and
/// keeping it explicit makes schema mismatches obvious.
class RoomMapper {
  RoomMapper._();

  static Room? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Room(
      id: json['_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      status: _statusFromString(json['status']?.toString()),
      ownerToken: json['ownerToken']?.toString() ?? '',
      config: _configFromJson(json['config']),
      players: _playersFromJson(json['players']),
      currentGame: _gameFromJson(json['currentGame']),
      currentRound: _roundFromJson(json['currentRound']),
    );
  }

  static RoomStatus _statusFromString(String? raw) {
    switch (raw) {
      case 'inGame':
        return RoomStatus.inGame;
      case 'ended':
        return RoomStatus.ended;
      case 'lobby':
      default:
        return RoomStatus.lobby;
    }
  }

  static GameConfig _configFromJson(Object? raw) {
    if (raw is! Map) {
      return const GameConfig(spyCount: 1, roundMinutes: 7, roundCount: 5);
    }
    return GameConfig(
      spyCount: _asInt(raw['spyCount'], 1),
      roundMinutes: _asInt(raw['roundMinutes'], 7),
      roundCount: _asInt(raw['roundCount'], 5),
    );
  }

  static List<Player> _playersFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((p) {
      return Player(
        id: p['_id']?.toString() ?? '',
        clientToken: p['clientToken']?.toString() ?? '',
        displayName: p['displayName']?.toString() ?? '',
        isReady: p['isReady'] == true,
        isOwner: p['isOwner'] == true,
        joinedAt: _asInt(p['joinedAt'], 0),
      );
    }).toList();
  }

  static GameSnapshot? _gameFromJson(Object? raw) {
    if (raw is! Map) return null;
    return GameSnapshot(
      id: raw['_id']?.toString() ?? '',
      status: raw['status']?.toString() ?? 'active',
      currentRoundIndex: _asInt(raw['currentRoundIndex'], 0),
      totalRounds: _asInt(raw['totalRounds'], 0),
    );
  }

  static RoundSnapshot? _roundFromJson(Object? raw) {
    if (raw is! Map) return null;
    return RoundSnapshot(
      id: raw['_id']?.toString() ?? '',
      index: _asInt(raw['index'], 0),
      startedAtMs: _asInt(raw['startedAtMs'], 0),
      endsAtMs: _asInt(raw['endsAtMs'], 0),
      status: raw['status']?.toString() ?? 'active',
      endedReason: raw['endedReason']?.toString(),
    );
  }

  static int _asInt(Object? v, int fallback) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
