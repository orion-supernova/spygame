import 'role.dart';

abstract interface class GameRepository {
  Stream<Role?> watchMyRole(String roundId, String locale);
  Stream<LocationsBoard> watchLocations(String code, String locale);
  Future<void> endRoundIfDue({
    required String roundId,
    required int expectedEndsAtMs,
  });
}
