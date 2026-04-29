import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/convex/convex_client_provider.dart';
import '../../../core/storage/identity_storage.dart';
import '../domain/game_repository.dart';
import '../domain/role.dart';
import 'convex_game_datasource.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final client = ref.watch(convexClientProvider);
  return ConvexGameRepository(client, IdentityStorage.instance);
});

final myRoleProvider =
    StreamProvider.family.autoDispose<Role?, String>((ref, roundId) {
  return ref.watch(gameRepositoryProvider).watchMyRole(roundId);
});

final locationsBoardProvider =
    StreamProvider.family.autoDispose<LocationsBoard, String>((ref, code) {
  return ref.watch(gameRepositoryProvider).watchLocations(code);
});
