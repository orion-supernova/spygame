import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../storage/identity_storage.dart';

/// Configures RevenueCat once at app startup. Must run AFTER
/// [IdentityStorage.init] so the persisted clientToken can be passed as
/// the RC `appUserID` — that maps the anonymous bearer-token identity
/// model onto RevenueCat's anonymous-user model without needing any
/// account system.
///
/// API keys are supplied at build time via `--dart-define`:
///   --dart-define=REVENUECAT_IOS_KEY=appl_xxx
///   --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
///
/// On web, [purchases_flutter] is unsupported — initialization is a
/// no-op and the marketplace falls back to browse-only.
class RevenueCatBootstrap {
  RevenueCatBootstrap._();

  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    if (_initialized) return;

    final apiKey = Platform.isIOS ? _iosKey : _androidKey;
    if (apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[iap] RevenueCat key missing — pass --dart-define=REVENUECAT_'
          '${Platform.isIOS ? 'IOS' : 'ANDROID'}_KEY=… to enable purchases.',
        );
      }
      return;
    }

    try {
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.warn);
      final config = PurchasesConfiguration(apiKey)
        ..appUserID = IdentityStorage.instance.clientToken;
      await Purchases.configure(config);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[iap] RevenueCat configure failed: $e');
    }
  }
}
