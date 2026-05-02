import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local mock for bundle ownership. Will be replaced by RevenueCat
/// entitlements later. No accounts means ownership is per-device only —
/// reinstalling the app loses the mock unlock, which is fine for this
/// pre-RevenueCat phase.
class OwnedBundlesStorage {
  OwnedBundlesStorage._();
  static final OwnedBundlesStorage instance = OwnedBundlesStorage._();

  static const _kKey = 'whereami.ownedBundleSlugs';

  late SharedPreferences _prefs;
  Set<String> _slugs = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) {
      _slugs = {};
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _slugs = decoded.whereType<String>().toSet();
      }
    } catch (_) {
      _slugs = {};
    }
  }

  Set<String> get slugs => Set.unmodifiable(_slugs);

  bool owns(String slug) => _slugs.contains(slug);

  Future<void> setOwned(String slug, bool owned) async {
    if (owned) {
      _slugs.add(slug);
    } else {
      _slugs.remove(slug);
    }
    await _prefs.setString(_kKey, jsonEncode(_slugs.toList()));
  }
}
