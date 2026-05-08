import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/game_summary_screen.dart';
import '../../features/identity/presentation/how_to_play_screen.dart';
import '../../features/identity/presentation/welcome_screen.dart';
import '../../features/marketplace/presentation/bundle_detail_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/room/presentation/home_screen.dart';
import '../../features/room/presentation/join_room_screen.dart';
import '../../features/room/presentation/lobby_screen.dart';

class AppRoute {
  AppRoute._();
  static const welcome = '/';
  static const home = '/home';
  static const howToPlay = '/how-to-play';
  static const marketplace = '/marketplace';
  static const bundleDetail = '/marketplace/:slug';
  static const join = '/join/:code';
  static const lobby = '/lobby/:code';
  static const game = '/game/:code';
  static const summary = '/summary/:code';

  static String joinFor(String code) => '/join/${code.toUpperCase()}';
  static String lobbyFor(String code) => '/lobby/$code';
  static String gameFor(String code) => '/game/$code';
  static String summaryFor(String code) => '/summary/$code';
  static String bundleDetailFor(String slug) => '/marketplace/$slug';
}

// Tracks route depth so transitions can play in reverse when navigating
// back to a shallower screen (close button, leave room, summary → home).
int _depthFor(String path) {
  if (path == AppRoute.welcome) return 0;
  if (path == AppRoute.home) return 1;
  if (path.startsWith('/join/')) return 1;
  if (path.startsWith('/lobby/')) return 2;
  if (path.startsWith('/game/')) return 3;
  if (path.startsWith('/summary/')) return 4;
  return 0;
}

int _lastDepth = -1;

bool _consumeReverse(String currentPath) {
  final depth = _depthFor(currentPath);
  final reverse = _lastDepth >= 0 && depth < _lastDepth;
  _lastDepth = depth;
  return reverse;
}

CustomTransitionPage<void> _slidePage({
  required LocalKey key,
  required Widget child,
  required bool reverse,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, _, page) {
      // Full-screen push: new page slides all the way in from the side.
      // Forward nav → from the right; back nav → from the left.
      final begin = reverse ? const Offset(-1, 0) : const Offset(1, 0);
      final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );
      return SlideTransition(position: slide, child: page);
    },
  );
}

// Modal-style entrance for tutorials / overlays pushed on top of the
// regular hierarchy. Slides up from the bottom and back down on dismiss.
CustomTransitionPage<void> _slideUpPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, _, page) {
      final slide = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );
      return SlideTransition(position: slide, child: page);
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.welcome,
    routes: [
      GoRoute(
        path: AppRoute.welcome,
        pageBuilder: (_, state) => _slidePage(
          key: state.pageKey,
          reverse: _consumeReverse(state.uri.path),
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.home,
        pageBuilder: (_, state) => _slidePage(
          key: state.pageKey,
          reverse: _consumeReverse(state.uri.path),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.howToPlay,
        pageBuilder: (_, state) => _slideUpPage(
          key: state.pageKey,
          child: const HowToPlayScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.marketplace,
        pageBuilder: (_, state) => _slideUpPage(
          key: state.pageKey,
          child: const MarketplaceScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.bundleDetail,
        pageBuilder: (_, state) => _slideUpPage(
          key: state.pageKey,
          child: BundleDetailScreen(
            slug: state.pathParameters['slug'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.join,
        pageBuilder: (_, state) => _slidePage(
          key: state.pageKey,
          reverse: _consumeReverse(state.uri.path),
          child: JoinRoomScreen(
            code: (state.pathParameters['code'] ?? '').toUpperCase(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.lobby,
        pageBuilder: (_, state) => _slidePage(
          key: state.pageKey,
          reverse: _consumeReverse(state.uri.path),
          child: LobbyScreen(
            code: (state.pathParameters['code'] ?? '').toUpperCase(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.game,
        pageBuilder: (_, state) => _slidePage(
          key: state.pageKey,
          reverse: _consumeReverse(state.uri.path),
          child: GameScreen(
            code: (state.pathParameters['code'] ?? '').toUpperCase(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.summary,
        pageBuilder: (_, state) => _slidePage(
          key: state.pageKey,
          reverse: _consumeReverse(state.uri.path),
          child: GameSummaryScreen(
            code: (state.pathParameters['code'] ?? '').toUpperCase(),
          ),
        ),
      ),
    ],
  );
});
