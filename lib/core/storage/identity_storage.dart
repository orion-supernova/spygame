import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persists the anonymous client token (a UUID v4 generated once), the last
/// display name the user typed, and the chosen UI/content language. The
/// client token is the bearer secret that Convex functions trust as the
/// user's identity — it is **never** embedded in invite links.
class IdentityStorage {
  IdentityStorage._();
  static final IdentityStorage instance = IdentityStorage._();

  static const _kTokenKey = 'whereami.clientToken';
  static const _kNameKey = 'whereami.lastDisplayName';
  static const _kLanguageKey = 'whereami.languageCode';
  static const _kDevModeKey = 'whereami.devMode';

  late SharedPreferences _prefs;
  late String _clientToken;
  String? _lastDisplayName;
  String? _languageCode;
  bool _devMode = false;

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
    _languageCode = _prefs.getString(_kLanguageKey);
    _devMode = _prefs.getBool(_kDevModeKey) ?? false;
  }

  String get clientToken => _clientToken;
  String? get lastDisplayName => _lastDisplayName;
  String? get languageCode => _languageCode;

  /// Whether the hidden runtime developer mode has been unlocked on this
  /// device (10-tap version gesture + server-verified code). Persists across
  /// launches so the unlock survives a relaunch; clears on reinstall.
  bool get devModeEnabled => _devMode;

  Future<void> setLastDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _lastDisplayName = trimmed;
    await _prefs.setString(_kNameKey, trimmed);
  }

  Future<void> setLanguageCode(String code) async {
    if (code != 'en' && code != 'tr') return;
    _languageCode = code;
    await _prefs.setString(_kLanguageKey, code);
  }

  Future<void> setDevMode(bool enabled) async {
    _devMode = enabled;
    await _prefs.setBool(_kDevModeKey, enabled);
  }
}
