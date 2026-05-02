import 'role.dart';

abstract interface class GameRepository {
  Stream<Role?> watchMyRole(String roundId, String locale);
  Stream<LocationsBoard> watchLocations(
    String code,
    String locale, {
    List<String> ownedBundleSlugs,
  });
  Future<void> endRoundIfDue({
    required String roundId,
    required int expectedEndsAtMs,
  });
}
