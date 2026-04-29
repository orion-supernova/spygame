import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/convex/convex_client_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/storage/identity_storage.dart';
import '../domain/game_repository.dart';
import '../domain/role.dart';
import 'convex_game_datasource.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final client = ref.watch(convexClientProvider);
  return ConvexGameRepository(client, IdentityStorage.instance);
});

// Locale is part of the family key by way of `ref.watch(localeProvider)`:
// when the user switches language, the dependency invalidates, autoDispose
// tears down the prior subscription, and a new one is opened with the
// updated `locale` arg. The role/location strings re-render in the new
// language without a screen rebuild.
final myRoleProvider =
    StreamProvider.family.autoDispose<Role?, String>((ref, roundId) {
  final locale = ref.watch(localeProvider).languageCode;
  return ref.watch(gameRepositoryProvider).watchMyRole(roundId, locale);
});

final locationsBoardProvider =
    StreamProvider.family.autoDispose<LocationsBoard, String>((ref, code) {
  final locale = ref.watch(localeProvider).languageCode;
  return ref.watch(gameRepositoryProvider).watchLocations(code, locale);
});
