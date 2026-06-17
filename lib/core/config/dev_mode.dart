import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/identity_storage.dart';

/// True when developer tools (mock purchases, simulated buy buttons, the
/// 1-player start override, etc.) should be available.
///
/// Always true in debug builds. In release builds it is unlocked at runtime
/// via the hidden 10-tap version-label gesture + server-verified code (see
/// `welcome_screen.dart`), persisted in [IdentityStorage]. This makes dev
/// mode reachable even on an App Store build — there is no way to read the
/// signed-in Apple ID, so the gesture+code is the gate instead.
///
/// Read this getter from non-widget code (notifiers, services). Widgets that
/// must rebuild when the flag flips should watch [devModeProvider] and OR it
/// with [kDebugMode] themselves.
bool get devToolsEnabled =>
    kDebugMode || IdentityStorage.instance.devModeEnabled;

/// Reactive view of the persisted runtime dev-mode flag. Does NOT fold in
/// [kDebugMode]; combine with it at the call site where the full
/// "tools available?" answer is needed.
final devModeProvider = StateNotifierProvider<DevModeController, bool>((ref) {
  return DevModeController();
});

class DevModeController extends StateNotifier<bool> {
  DevModeController() : super(IdentityStorage.instance.devModeEnabled);

  Future<void> enable() async {
    await IdentityStorage.instance.setDevMode(true);
    state = true;
  }

  Future<void> disable() async {
    await IdentityStorage.instance.setDevMode(false);
    state = false;
  }
}
