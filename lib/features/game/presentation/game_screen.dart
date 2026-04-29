import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/convex/server_time_provider.dart';
import '../../../core/lifecycle/app_lifecycle_observer.dart';
import '../../../core/notifications/round_end_notifier.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/identity_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../core/utils/haptics.dart';
import '../../room/data/room_providers.dart';
import '../../room/domain/room.dart';
import '../data/game_providers.dart';
import 'controllers/countdown_controller.dart';
import 'location_grid.dart';
import 'role_card.dart';
import 'widgets/intermission_panel.dart';
import 'widgets/parallax_fade.dart';
import 'widgets/scroll_hint.dart';
import 'widgets/starting_countdown.dart';
import 'widgets/timer_header_delegate.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? _scheduledForRoundId;
  int _lastSecondHaptic = -1;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    WakelockPlus.enable();
    // Refresh server-time offset on entry.
    // ignore: discarded_futures
    Future.microtask(
      () => ref.read(serverTimeOffsetProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    WakelockPlus.disable();
    // ignore: discarded_futures
    RoundEndNotifier.instance.cancelAll();
    super.dispose();
  }

  Future<void> _scheduleEndNotification(RoundSnapshot round) async {
    if (_scheduledForRoundId == round.id) return;
    _scheduledForRoundId = round.id;
    await RoundEndNotifier.instance.cancelAll();
    final offset = ref.read(serverTimeOffsetProvider);
    final endsLocalMs = round.endsAtMs - offset;
    await RoundEndNotifier.instance.scheduleAt(
      notificationId: round.index,
      endsAtLocalMs: endsLocalMs,
      title: 'Time\'s up',
      body: 'Round ${round.index} just ended. Open the app.',
    );
  }

  Future<void> _maybeOpportunisticEnd(RoundSnapshot round) async {
    final offset = ref.read(serverTimeOffsetProvider);
    final nowServer = DateTime.now().millisecondsSinceEpoch + offset;
    if (nowServer >= round.endsAtMs && round.isActive) {
      await ref.read(gameRepositoryProvider).endRoundIfDue(
            roundId: round.id,
            expectedEndsAtMs: round.endsAtMs,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRoom = ref.watch(roomStreamProvider(widget.code));
    final myToken = IdentityStorage.instance.clientToken;

    ref.listen(appLifecycleProvider, (prev, next) {
      if (next != AppLifecycleState.resumed) return;
      asyncRoom.whenData((room) async {
        final round = room?.currentRound;
        if (round == null) return;
        await _maybeOpportunisticEnd(round);
        if (round.isActive) {
          _scheduledForRoundId = null;
          await _scheduleEndNotification(round);
        }
      });
    });

    ref.listen(roomStreamProvider(widget.code), (prev, next) {
      next.whenData((room) async {
        if (room == null) return;
        if (room.status == RoomStatus.ended && mounted) {
          context.go(AppRoute.summaryFor(room.code));
          return;
        }
        final round = room.currentRound;
        if (round != null && round.isActive) {
          await _scheduleEndNotification(round);
        } else if (round != null && !round.isActive) {
          await RoundEndNotifier.instance.cancelAll();
          _scheduledForRoundId = null;
        }
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.ink)),
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            child: asyncRoom.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              data: (room) {
                if (room == null) {
                  return const Center(child: Text('Room ended.'));
                }
                return _GameBody(
                  room: room,
                  myToken: myToken,
                  onSecondHaptic: (s) {
                    if (s != _lastSecondHaptic && s <= 10 && s > 0) {
                      _lastSecondHaptic = s;
                      Haptics.warning();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameBody extends ConsumerWidget {
  const _GameBody({
    required this.room,
    required this.myToken,
    required this.onSecondHaptic,
  });

  final Room room;
  final String myToken;
  final ValueChanged<int> onSecondHaptic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = room.currentGame;
    if (game == null) {
      return const Center(child: Text('Setting up round…'));
    }

    final isOwner = room.isOwner(myToken);
    final phase = game.phase;
    final round = room.currentRound;

    if (phase == GamePhase.playing && round != null) {
      return _PlayingScreen(
        room: room,
        game: game,
        round: round,
        myToken: myToken,
        isOwner: isOwner,
        onSecondHaptic: onSecondHaptic,
      );
    }

    final asyncBoard = ref.watch(locationsBoardProvider(room.code));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        _TopBar(
          room: room,
          isOwner: isOwner,
          label: _headerLabel(phase, game, round?.index),
        ),
        const SizedBox(height: 16),
        if (phase == GamePhase.between)
          IntermissionPanel(
            room: room,
            myToken: myToken,
            lastRoundIndex: round?.index ?? game.currentRoundIndex,
            totalRounds: game.totalRounds,
            onToggleReady: () async {
              final me = room.playerFor(myToken);
              await Haptics.selection();
              await ref.read(roomRepositoryProvider).setReady(
                    code: room.code,
                    ready: !(me?.isReady ?? false),
                  );
            },
          )
        else if (phase == GamePhase.starting &&
            game.nextRoundStartsAtMs != null)
          StartingCountdown(
            startsAtServerMs: game.nextRoundStartsAtMs!,
            roundIndex: game.currentRoundIndex + 1,
          ),
        const SizedBox(height: 24),
        Text(
          'LOCATIONS',
          style: AppTypography.mono(
            size: 11,
            letterSpacing: 2,
            color: AppColors.paperFaint,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Played venues are crossed out.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.paperFaint),
        ),
        const SizedBox(height: 14),
        asyncBoard.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            ),
          ),
          error: (e, _) => Text(
            e.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          data: (board) => LocationGrid(board: board),
        ),
      ],
    );
  }
}

String _headerLabel(GamePhase phase, GameSnapshot game, int? roundIndex) {
  switch (phase) {
    case GamePhase.between:
      return 'INTERMISSION · ROUND ${roundIndex ?? 0} OF ${game.totalRounds}';
    case GamePhase.starting:
      return 'GET READY · ROUND ${game.currentRoundIndex + 1} OF ${game.totalRounds}';
    case GamePhase.ended:
      return 'GAME OVER';
    case GamePhase.playing:
      return 'ROUND ${roundIndex ?? game.currentRoundIndex} OF ${game.totalRounds}';
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.room,
    required this.isOwner,
    required this.label,
  });

  final Room room;
  final bool isOwner;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          onPressed: () async {
            final confirmed = await _confirmLeave(context, isOwner: isOwner);
            if (!confirmed) return;
            await ref
                .read(roomRepositoryProvider)
                .leaveRoom(code: room.code);
            if (!context.mounted) return;
            context.go(AppRoute.home);
          },
          icon: const Icon(Icons.close, color: AppColors.paper),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.mono(
            size: 11,
            letterSpacing: 2.2,
            color: AppColors.paperFaint,
          ),
        ),
      ],
    );
  }
}

class _PlayingScreen extends ConsumerStatefulWidget {
  const _PlayingScreen({
    required this.room,
    required this.game,
    required this.round,
    required this.myToken,
    required this.isOwner,
    required this.onSecondHaptic,
  });

  final Room room;
  final GameSnapshot game;
  final RoundSnapshot round;
  final String myToken;
  final bool isOwner;
  final ValueChanged<int> onSecondHaptic;

  @override
  ConsumerState<_PlayingScreen> createState() => _PlayingScreenState();
}

class _PlayingScreenState extends ConsumerState<_PlayingScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _locationsHeaderKey = GlobalKey();
  static const double _timerMinExtent = 64;
  bool _snapping = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _scrollToLocations() async {
    final ctx = _locationsHeaderKey.currentContext;
    if (ctx == null) return;
    // Fire haptic without awaiting so the BuildContext stays valid.
    // ignore: discarded_futures, unawaited_futures
    Haptics.selection();
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  /// Snap the scroll to either fully-hero (offset 0) or fully-collapsed
  /// (offset = morphRange) so users never end up parked mid-transition.
  bool _maybeSnap(double heroExtent) {
    if (_snapping || !_scroll.hasClients) return false;
    final offset = _scroll.offset;
    final morphRange = heroExtent - _timerMinExtent;
    if (offset <= 0.5 || offset >= morphRange - 0.5) return false;
    final target = offset < morphRange / 2 ? 0.0 : morphRange;
    _snapping = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scroll.hasClients) {
        _snapping = false;
        return;
      }
      try {
        await _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } finally {
        _snapping = false;
      }
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    final totalMs = (round.endsAtMs - round.startedAtMs).clamp(1, 1 << 30);
    final args = CountdownArgs(
      endsAtServerMs: round.endsAtMs,
      totalMs: totalMs,
    );
    final countdown = ref.watch(countdownControllerProvider(args));
    final asyncRole = ref.watch(myRoleProvider(round.id));
    final asyncBoard = ref.watch(locationsBoardProvider(widget.room.code));
    widget.onSecondHaptic(countdown.seconds);

    final viewportH = MediaQuery.of(context).size.height;
    final heroExtent = (viewportH * 0.32).clamp(220.0, 300.0);

    final label =
        round.isActive ? 'TIME REMAINING' : 'ROUND ENDED';
    final roundLabel =
        'ROUND ${round.index} OF ${widget.game.totalRounds}';

    return NotificationListener<ScrollEndNotification>(
      onNotification: (n) {
        _maybeSnap(heroExtent);
        return false;
      },
      child: CustomScrollView(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _TopBar(
              room: widget.room,
              isOwner: widget.isOwner,
              label: roundLabel,
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: TimerHeaderDelegate(
            progress: countdown.progress,
            seconds: countdown.seconds,
            totalSeconds: (totalMs / 1000).round(),
            label: label,
            maxExtent: heroExtent,
          ),
        ),
        SliverToBoxAdapter(
          child: ParallaxFade(
            controller: _scroll,
            fadeRange: heroExtent * 0.7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                children: [
                  asyncRole.when(
                    loading: () => const SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.lime,
                        ),
                      ),
                    ),
                    error: (_, _) => const RoleCard(role: null),
                    data: (role) => RoleCard(role: role),
                  ),
                  if (widget.isOwner) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: round.isActive
                          ? () async {
                              await Haptics.warning();
                              await ref
                                  .read(roomRepositoryProvider)
                                  .endRoundManual(code: widget.room.code);
                            }
                          : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('END ROUND NOW'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ScrollHint(
                    onTap: _scrollToLocations,
                    opacity: 1.0,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          key: _locationsHeaderKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCATIONS',
                  style: AppTypography.mono(
                    size: 11,
                    letterSpacing: 2,
                    color: AppColors.paperFaint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Played venues are crossed out.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.paperFaint),
                ),
              ],
            ),
          ),
        ),
        asyncBoard.when(
          loading: () => const SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              ),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                e.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          data: (board) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverLocationGrid(board: board),
          ),
        ),
      ],
      ),
    );
  }
}

Future<bool> _confirmLeave(
  BuildContext context, {
  required bool isOwner,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.inkRaised,
      title: const Text('Leave game?'),
      content: Text(
        isOwner
            ? 'You\'ll leave the round in progress. The game continues '
                'for everyone else and host duties pass to another player. '
                'You can\'t rejoin afterwards.'
            : 'You\'ll leave the round in progress. The game continues '
                'for everyone else, and you can\'t rejoin afterwards.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('STAY'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.signalRed),
          child: const Text('LEAVE'),
        ),
      ],
    ),
  );
  return result ?? false;
}
