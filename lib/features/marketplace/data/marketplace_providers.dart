import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/convex/convex_client_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../domain/bundle.dart';
import 'bundles_repository.dart';
import 'owned_bundles_storage.dart';

final bundlesRepositoryProvider = Provider<BundlesRepository>((ref) {
  final client = ref.watch(convexClientProvider);
  return BundlesRepository(client);
});

/// All real (server-backed) bundles, locale-projected.
final bundlesProvider = FutureProvider.autoDispose<List<Bundle>>((ref) async {
  final repo = ref.watch(bundlesRepositoryProvider);
  final locale = ref.watch(localeProvider).languageCode;
  return repo.list(locale: locale);
});

/// Single bundle's detail view (locations + sample roles).
final bundleDetailProvider = FutureProvider.autoDispose
    .family<BundleDetail, String>((ref, slug) async {
  final repo = ref.watch(bundlesRepositoryProvider);
  final locale = ref.watch(localeProvider).languageCode;
  return repo.detail(slug: slug, locale: locale);
});

/// Locally-owned bundle slugs. Mock for now (SharedPreferences); will
/// move to RevenueCat entitlements later.
class OwnedBundlesNotifier extends StateNotifier<Set<String>> {
  OwnedBundlesNotifier() : super(OwnedBundlesStorage.instance.slugs);

  Future<void> setOwned(String slug, bool owned) async {
    await OwnedBundlesStorage.instance.setOwned(slug, owned);
    state = OwnedBundlesStorage.instance.slugs;
  }
}

final ownedBundlesProvider =
    StateNotifierProvider<OwnedBundlesNotifier, Set<String>>(
  (ref) => OwnedBundlesNotifier(),
);

/// Coming-soon placeholders rendered alongside real bundles to make the
/// storefront feel populated. Pure client-side data — no server entry.
/// Paris/Tokyo/Stockholm graduated to real server-backed bundles; Sci-Fi
/// stays here until it's authored.
final placeholderBundlesProvider = Provider<List<Bundle>>((ref) {
  return const [
    Bundle(
      slug: '_coming_scifi',
      title: 'Sci-Fi',
      tagline: 'Wormholes, colonies, and pirates.',
      priceDisplay: '—',
      locationCount: 0,
      category: BundleCategory.theme,
      accentColor: Color(0xFFFEE440),
      icon: Icons.rocket_launch_rounded,
      isPlaceholder: true,
    ),
  ];
});
