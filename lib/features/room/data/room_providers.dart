import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/convex/convex_client_provider.dart';
import '../../../core/storage/identity_storage.dart';
import '../domain/room.dart';
import '../domain/room_repository.dart';
import 'convex_room_datasource.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final client = ref.watch(convexClientProvider);
  return ConvexRoomRepository(client, IdentityStorage.instance);
});

final roomStreamProvider =
    StreamProvider.family.autoDispose<Room?, String>((ref, code) {
  final repo = ref.watch(roomRepositoryProvider);
  return repo.watchRoom(code);
});
