import 'room.dart';

abstract interface class RoomRepository {
  Future<String> createRoom({required String displayName});
  Future<String> joinRoom({required String code, required String displayName});
  Future<void> leaveRoom({required String code});
  Future<void> setReady({required String code, required bool ready});
  Future<void> updateConfig({required String code, required GameConfig config});
  Future<void> setDisabledLocations({
    required String code,
    required List<String> disabledLocationIds,
  });
  Future<void> heartbeat({required String code});
  Future<void> startGame({
    required String code,
    required List<String> ownedBundleSlugs,
  });
  Future<void> endRoundManual({required String code});

  Stream<Room?> watchRoom(String code);
}
