import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/iap/revenuecat_bootstrap.dart';

/// The single boundary between the app and `purchases_flutter`. Wraps the
/// RC SDK with a small typed surface — the Riverpod layer and UI never
/// touch [Purchases] directly.
///
/// Entitlement IDs in the RevenueCat dashboard MUST equal the bundle
/// slugs (`istanbul`, `paris`, `tokyo`, `stockholm`, `cyberpunk`) so the
/// existing location-gating in `convex/games.ts` keeps working without
/// changes.
class IapService {
  IapService._();

  static final IapService instance = IapService._();

  final StreamController<Set<String>> _entitlementsController =
      StreamController<Set<String>>.broadcast();
  bool _listenerRegistered = false;

  bool get _supported {
    if (kIsWeb) return false;
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    return RevenueCatBootstrap.isInitialized;
  }

  bool get isAvailable => _supported;

  /// Live updates whenever RC's CustomerInfo changes — purchases,
  /// restores, refunds, sandbox revocations, etc. Always emits the FULL
  /// current set (not deltas). Listener is attached lazily so the
  /// service is safe to construct before [RevenueCatBootstrap.initialize]
  /// completes.
  Stream<Set<String>> get entitlementUpdates {
    _ensureListenerRegistered();
    return _entitlementsController.stream;
  }

  void _ensureListenerRegistered() {
    if (_listenerRegistered || !_supported) return;
    _listenerRegistered = true;
    Purchases.addCustomerInfoUpdateListener(
      (info) => _entitlementsController.add(_extractSlugs(info)),
    );
  }

  /// Pulls the current entitlement set on demand. Used to seed the
  /// Riverpod state on app start.
  Future<Set<String>> currentEntitlementSlugs() async {
    if (!_supported) return const <String>{};
    _ensureListenerRegistered();
    try {
      final info = await Purchases.getCustomerInfo();
      return _extractSlugs(info);
    } catch (e) {
      if (kDebugMode) debugPrint('[iap] getCustomerInfo failed: $e');
      return const <String>{};
    }
  }

  /// Loads the storefront offering. Returns null on web or when RC is
  /// unconfigured so the UI can fall back to Convex `priceUsd`.
  Future<Offering?> loadDefaultOffering() async {
    if (!_supported) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      if (kDebugMode) debugPrint('[iap] getOfferings failed: $e');
      return null;
    }
  }

  /// Buys a package and returns the updated entitlement set. Throws
  /// [PlatformException] / [PurchasesErrorCode] on failure — callers
  /// should swallow [PurchasesErrorCode.purchaseCancelledError] silently
  /// and snackbar everything else.
  Future<Set<String>> purchasePackage(Package package) async {
    if (!_supported) return const <String>{};
    _ensureListenerRegistered();
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return _extractSlugs(result.customerInfo);
  }

  /// Replays platform receipts — works without our own user ID because
  /// Apple/Google receipts are tied to the store account.
  Future<Set<String>> restore() async {
    if (!_supported) return const <String>{};
    _ensureListenerRegistered();
    final info = await Purchases.restorePurchases();
    return _extractSlugs(info);
  }

  static Set<String> _extractSlugs(CustomerInfo info) {
    return info.entitlements.active.keys.toSet();
  }
}

/// Resolves the RC [Package] for a bundle slug from an offering: exact
/// package-identifier match first, then store-product-ID suffix fallback
/// in case the RC package identifiers were left as default values rather
/// than slugs.
Package? findPackageForSlug(Offering? offering, String slug) {
  if (offering == null) return null;
  for (final p in offering.availablePackages) {
    if (p.identifier == slug) return p;
    if (p.storeProduct.identifier.endsWith('.$slug') ||
        p.storeProduct.identifier.endsWith('_$slug')) {
      return p;
    }
  }
  return null;
}
