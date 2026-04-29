import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/game_summary_screen.dart';
import '../../features/identity/presentation/welcome_screen.dart';
import '../../features/room/presentation/home_screen.dart';
import '../../features/room/presentation/lobby_screen.dart';

class AppRoute {
  AppRoute._();
  static const welcome = '/';
  static const home = '/home';
  static const lobby = '/lobby/:code';
  static const game = '/game/:code';
  static const summary = '/summary/:code';

  static String lobbyFor(String code) => '/lobby/$code';
  static String gameFor(String code) => '/game/$code';
  static String summaryFor(String code) => '/summary/$code';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.welcome,
    routes: [
      GoRoute(
        path: AppRoute.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoute.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.lobby,
        builder: (_, state) => LobbyScreen(
          code: (state.pathParameters['code'] ?? '').toUpperCase(),
        ),
      ),
      GoRoute(
        path: AppRoute.game,
        builder: (_, state) => GameScreen(
          code: (state.pathParameters['code'] ?? '').toUpperCase(),
        ),
      ),
      GoRoute(
        path: AppRoute.summary,
        builder: (_, state) => GameSummaryScreen(
          code: (state.pathParameters['code'] ?? '').toUpperCase(),
        ),
      ),
    ],
  );
});
