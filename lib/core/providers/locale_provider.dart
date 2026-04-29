import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/identity_storage.dart';

const supportedLocaleCodes = <String>['en', 'tr'];
const _defaultLocale = Locale('en');

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_initial());

  static Locale _initial() {
    final stored = IdentityStorage.instance.languageCode;
    if (stored != null && supportedLocaleCodes.contains(stored)) {
      return Locale(stored);
    }
    final device = PlatformDispatcher.instance.locale.languageCode;
    return supportedLocaleCodes.contains(device)
        ? Locale(device)
        : _defaultLocale;
  }

  Future<void> setLocale(String code) async {
    if (!supportedLocaleCodes.contains(code)) return;
    if (state.languageCode == code) return;
    await IdentityStorage.instance.setLanguageCode(code);
    state = Locale(code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (_) => LocaleNotifier(),
);
