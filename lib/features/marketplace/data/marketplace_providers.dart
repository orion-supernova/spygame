import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/convex/convex_client_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../domain/bundle.dart';
import 'bundles_repository.dart';
import 'iap_service.dart';

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

/// Boundary to RevenueCat. Singleton; the same instance backs both this
/// provider and [OwnedBundlesNotifier] below.
final iapServiceProvider = Provider<IapService>((_) => IapService.instance);

/// The current RC offering (5 packages, one per bundle slug). `null` on
/// web or when RC is not configured — the UI falls back to the Convex
/// `priceUsd` display string in that case.
final defaultOfferingProvider = FutureProvider.autoDispose<Offering?>((ref) {
  return ref.watch(iapServiceProvider).loadDefaultOffering();
});

/// Set of bundle slugs the current store account owns.
///
/// Backed by RevenueCat: the store receipt itself (signed by Apple /
/// Google) is the proof of ownership — no server-side cache, no user
/// records. The notifier seeds from `getCustomerInfo()` on construction
/// and then mirrors every `addCustomerInfoUpdateListener` callback so
/// purchases, restores, and refunds all flow through the same Riverpod
/// stream that existing readers (`lobby_screen`, `locations_picker`,
/// `game_providers`) already watch synchronously.
class OwnedBundlesNotifier extends StateNotifier<Set<String>> {
  OwnedBundlesNotifier(this._iap) : super(const <String>{}) {
    _seed();
    _sub = _iap.entitlementUpdates.listen((slugs) {
      if (mounted) state = slugs;
    });
  }

  final IapService _iap;
  StreamSubscription<Set<String>>? _sub;

  Future<void> _seed() async {
    final initial = await _iap.currentEntitlementSlugs();
    if (mounted) state = initial;
  }

  /// Triggers the platform purchase flow. On success returns true and the
  /// updated entitlements arrive via the stream listener (so [state]
  /// updates automatically — no need to set it here).
  Future<bool> purchasePackage(Package package) async {
    try {
      final updated = await _iap.purchasePackage(package);
      if (mounted) state = updated;
      return true;
    } on PlatformException catch (e) {
      // RC throws PlatformException; the user-cancel code is non-fatal.
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  /// Replays receipts. Returns the set of slugs after restore so the UI
  /// can tell the user how many bundles came back.
  Future<Set<String>> restore() async {
    final updated = await _iap.restore();
    if (mounted) state = updated;
    return updated;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final ownedBundlesProvider =
    StateNotifierProvider<OwnedBundlesNotifier, Set<String>>(
  (ref) => OwnedBundlesNotifier(ref.watch(iapServiceProvider)),
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
