import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/room/data/room_providers.dart';
import '../router/app_router.dart';
import 'app_skin.dart';

/// Maps a bundle slug (or null) to the skin that should drive the UI.
/// Unknown/null slugs fall back to the default noir look.
SkinId skinIdFromSlug(String? slug) => switch (slug) {
      'cyberpunk' => SkinId.cyberpunk,
      'victorian-1800s' => SkinId.victorian,
      'wild-west' => SkinId.wildWest,
      _ => SkinId.noir,
    };

/// Bridges GoRouter's `Listenable` navigation events into Riverpod so
/// [activeRoomCodeProvider] recomputes on every push/pop. Listens without
/// owning the delegate (we must not dispose the app's router delegate).
class _RouterTick extends ChangeNotifier {
  _RouterTick(this._delegate) {
    _delegate.addListener(notifyListeners);
  }

  final Listenable _delegate;

  @override
  void dispose() {
    _delegate.removeListener(notifyListeners);
    super.dispose();
  }
}

final _routerTickProvider = ChangeNotifierProvider<_RouterTick>((ref) {
  final router = ref.watch(routerProvider);
  return _RouterTick(router.routerDelegate);
});

/// The room code of the screen currently on top (lobby / game / summary),
/// or null when the user is outside any room. Recomputes on navigation.
final activeRoomCodeProvider = Provider<String?>((ref) {
  ref.watch(_routerTickProvider);
  final router = ref.watch(routerProvider);
  final path = router.routerDelegate.currentConfiguration.uri.path;
  for (final prefix in const ['/lobby/', '/game/', '/summary/']) {
    if (path.startsWith(prefix)) {
      return path.substring(prefix.length).toUpperCase();
    }
  }
  return null;
});

/// Resolves which skin is active. Outside a room → noir. Inside a room →
/// driven by the room's `activeThemeSlug`, watched via `.select` so only a
/// theme change (not every room heartbeat) re-derives the id.
final activeSkinIdProvider = Provider<SkinId>((ref) {
  final code = ref.watch(activeRoomCodeProvider);
  if (code == null) return SkinId.noir;
  return ref.watch(
    roomStreamProvider(code).select(
      (async) => skinIdFromSlug(async.valueOrNull?.activeThemeSlug),
    ),
  );
});

/// The resolved skin tokens handed to `AppTheme.fromSkin` at the app root.
final activeSkinProvider = Provider<AppSkin>(
  (ref) => AppSkin.byId(ref.watch(activeSkinIdProvider)),
);
