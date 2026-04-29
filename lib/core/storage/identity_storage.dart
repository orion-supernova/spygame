import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persists the anonymous client token (a UUID v4 generated once) and the
/// last display name the user typed. The client token is the bearer secret
/// that Convex functions trust as the user's identity — it is **never**
/// embedded in invite links.
class IdentityStorage {
  IdentityStorage._();
  static final IdentityStorage instance = IdentityStorage._();

  static const _kTokenKey = 'whereami.clientToken';
  static const _kNameKey = 'whereami.lastDisplayName';

  late SharedPreferences _prefs;
  late String _clientToken;
  String? _lastDisplayName;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs.getString(_kTokenKey);
    if (stored == null || stored.isEmpty) {
      _clientToken = const Uuid().v4();
      await _prefs.setString(_kTokenKey, _clientToken);
    } else {
      _clientToken = stored;
    }
    _lastDisplayName = _prefs.getString(_kNameKey);
  }

  String get clientToken => _clientToken;
  String? get lastDisplayName => _lastDisplayName;

  Future<void> setLastDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _lastDisplayName = trimmed;
    await _prefs.setString(_kNameKey, trimmed);
  }
}
