import 'package:meta/meta.dart';

@immutable
class Role {
  const Role._({
    required this.isSpy,
    required this.label,
    required this.locationName,
    required this.roundIndex,
  });

  factory Role.spy({required int roundIndex}) => Role._(
        isSpy: true,
        label: 'YOU ARE THE SPY',
        locationName: null,
        roundIndex: roundIndex,
      );

  factory Role.civilian({
    required String label,
    required String locationName,
    required int roundIndex,
  }) =>
      Role._(
        isSpy: false,
        label: label,
        locationName: locationName,
        roundIndex: roundIndex,
      );

  final bool isSpy;
  final String label;
  final String? locationName;
  final int roundIndex;
}

@immutable
class LocationItem {
  const LocationItem({required this.id, required this.name});
  final String id;
  final String name;
}

@immutable
class LocationsBoard {
  const LocationsBoard({required this.locations, required this.playedIds});
  final List<LocationItem> locations;
  final Set<String> playedIds;

  bool isPlayed(String id) => playedIds.contains(id);
}
