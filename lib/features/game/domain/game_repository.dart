import 'role.dart';

abstract interface class GameRepository {
  Stream<Role?> watchMyRole(String roundId);
  Stream<LocationsBoard> watchLocations(String code);
  Future<void> endRoundIfDue({
    required String roundId,
    required int expectedEndsAtMs,
  });
}
