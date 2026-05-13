import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/convex/server_time_provider.dart';
import '../../../core/lifecycle/app_lifecycle_observer.dart';
import '../../../core/notifications/live_timer_controller.dart';
import '../../../core/notifications/push_token_service.dart';
import '../../../core/notifications/round_end_notifier.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/identity_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../room/data/room_providers.dart';
import '../../room/domain/room.dart';
import '../data/game_providers.dart';
import 'controllers/countdown_controller.dart';
import 'location_grid.dart';
import 'role_card.dart';
import 'widgets/intermission_panel.dart';
import 'widgets/scroll_hint.dart';
import 'widgets/spy_reveal_dialog.dart';
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
  int? _shownSpyRevealForRound;
  bool _endNavInFlight = false;
  int _lastSecondHaptic = -1;
  Timer? _heartbeat;

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
    // Keep `players.lastSeenAt` fresh during the game so the server reaper
    // can tell a foregrounded app from a closed/killed one. Timer.periodic
    // is naturally suspended when the OS pauses the app, which is exactly
    // the signal we want.
    // ignore: discarded_futures
    ref.read(roomRepositoryProvider).heartbeat(code: widget.code);
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      // ignore: discarded_futures
      ref.read(roomRepositoryProvider).heartbeat(code: widget.code);
    });
    // Register push tokens for the round-end "Round ended" fan-out. On
    // Android this acquires the FCM token and ships it; on iOS the per-
    // activity APNs token will arrive separately when the Live Activity
    // boots.
    // ignore: discarded_futures
    PushTokenService.instance.bindToRoom(widget.code);
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    // ignore: discarded_futures
    WakelockPlus.disable();
    // ignore: discarded_futures
    RoundEndNotifier.instance.cancelAll();
    // ignore: discarded_futures
    LiveTimerController.instance.end();
    PushTokenService.instance.unbind();
    super.dispose();
  }

  Future<void> _scheduleEndNotification(RoundSnapshot round) async {
    if (_scheduledForRoundId == round.id) return;
    _scheduledForRoundId = round.id;
    await RoundEndNotifier.instance.cancelAll();
    final offset = ref.read(serverTimeOffsetProvider);
    final endsLocalMs = round.endsAtMs - offset;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final game = ref.read(roomStreamProvider(widget.code)).valueOrNull?.currentGame;
    final totalRounds = game?.totalRounds ?? 0;
    await RoundEndNotifier.instance.scheduleAt(
      notificationId: round.index,
      endsAtLocalMs: endsLocalMs,
      title: l10n.notifRoundEndTitle,
      body: l10n.notifRoundEndBody(round.index),
    );
    await LiveTimerController.instance.start(
      roundId: round.id,
      roomCode: widget.code,
      roundIndex: round.index,
      totalRounds: totalRounds,
      endsAtLocalMs: endsLocalMs,
      title: l10n.liveTimerTitle(round.index, totalRounds),
      body: l10n.liveTimerSubtitle(widget.code),
    );
  }

  Future<void> _maybeOpportunisticEnd(RoundSnapshot round) async {
    final offset = ref.read(serverTimeOffsetProvider);
    final nowServer = DateTime.now().millisecondsSinceEpoch + offset;
    if (nowServer >= round.endsAtMs && round.isActive) {
      await ref
          .read(gameRepositoryProvider)
          .endRoundIfDue(roundId: round.id, expectedEndsAtMs: round.endsAtMs);
    }
  }

  Future<void> _maybeShowSpyReveal(Room room) async {
    final game = room.currentGame;
    final revealIdx = game?.lastSpyRevealRoundIndex;
    final spyToken = game?.lastSpyClientToken;
    if (revealIdx == null || spyToken == null) return;
    if (revealIdx == _shownSpyRevealForRound) return;
    _shownSpyRevealForRound = revealIdx;
    final spy = room.playerFor(spyToken);
    if (spy == null) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SpyRevealDialog(
        roundIndex: revealIdx,
        spyName: spy.displayName,
      ),
    );
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
        ref
            .read(serverTimeOffsetProvider.notifier)
            .observeServerNow(room.serverNowMs);
        if (room.status == RoomStatus.ended) {
          // Guard against racing emissions: only one end-game flow runs.
          // Show the spy reveal modal first, then navigate to the summary
          // once the user dismisses it.
          if (_endNavInFlight) return;
          _endNavInFlight = true;
          await _maybeShowSpyReveal(room);
          if (!context.mounted) return;
          await LiveTimerController.instance.end();
          if (!context.mounted) return;
          context.go(AppRoute.summaryFor(room.code));
          return;
        }
        await _maybeShowSpyReveal(room);
        final round = room.currentRound;
        if (round != null && round.isActive) {
          await _scheduleEndNotification(round);
        } else if (round != null && !round.isActive) {
          // Round just ended. Drop the pre-scheduled "round end" local
          // notification (if it's still pending — common for host-ended
          // rounds) and dismiss the Live Activity / chronometer. The in-app
          // UI flips visibly on its own, so we deliberately do NOT post an
          // additional "Round ended" alert here.
          await RoundEndNotifier.instance.cancelAll();
          await LiveTimerController.instance.end();
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
            bottom: false,
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
                  final l10n = AppLocalizations.of(context);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Text(
                          l10n.gameRoomEnded,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: AppColors.paper,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => context.go(AppRoute.home),
                          child: Text(l10n.joinScreenCtaBackHome),
                        ),
                      ],
                    ),
                  );
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
    final l10n = AppLocalizations.of(context);
    final game = room.currentGame;
    if (game == null) {
      return Center(child: Text(l10n.gameSettingUp));
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
          label: _headerLabel(l10n, phase, game, round?.index),
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
              await ref.read(serverTimeOffsetProvider.notifier).refresh();
              await ref
                  .read(roomRepositoryProvider)
                  .setReady(code: room.code, ready: !(me?.isReady ?? false));
            },
          )
        else if (phase == GamePhase.starting &&
            game.nextRoundStartsAtMs != null)
          StartingCountdown(
            startsAtServerMs: game.nextRoundStartsAtMs!,
            snapshotServerNowMs: room.serverNowMs,
            snapshotReceivedAtLocalMs: room.receivedAtLocalMs,
            roundIndex: game.currentRoundIndex + 1,
          ),
        const SizedBox(height: 24),
        Text(
          l10n.gameLocationsEyebrow,
          style: AppTypography.mono(
            size: 11,
            letterSpacing: 2,
            color: AppColors.paperFaint,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.gameLocationsHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.paperFaint),
        ),
        const SizedBox(height: 14),
        asyncBoard.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            ),
          ),
          error: (_, _) => Text(
            l10n.errorUnknown,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          data: (board) => LocationGrid(board: board),
        ),
      ],
    );
  }
}

String _headerLabel(
  AppLocalizations l10n,
  GamePhase phase,
  GameSnapshot game,
  int? roundIndex,
) {
  switch (phase) {
    case GamePhase.between:
      return l10n.gameIntermissionXOfY(roundIndex ?? 0, game.totalRounds);
    case GamePhase.starting:
      return l10n.gameGetReadyXOfY(
        game.currentRoundIndex + 1,
        game.totalRounds,
      );
    case GamePhase.ended:
      return l10n.gameOverEyebrow;
    case GamePhase.playing:
      return l10n.gameRoundXOfY(
        roundIndex ?? game.currentRoundIndex,
        game.totalRounds,
      );
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
            await ref.read(roomRepositoryProvider).leaveRoom(code: room.code);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    final mq = MediaQuery.of(context);
    final viewportW = mq.size.width;
    // The outer SafeArea uses bottom: false so the ink + grain background
    // extends to the screen edge. We pad the bottom of the scroll content
    // ourselves so interactive elements clear the iOS home indicator.
    final bottomInset = mq.padding.bottom;
    final safeH = mq.size.height - mq.padding.top;
    // Reserve vertical space below the timer for: TopBar 56 +
    // padding-top 12 + RoleCard 220 + ScrollHint 84 + padding-bottom 12
    // + bottomInset (home indicator clearance) + (owner: 12 + 48).
    final reservedBelowTimer = 56.0 +
        12 +
        220 +
        84 +
        12 +
        bottomInset +
        (widget.isOwner ? 60 : 0);
    final heightCap = safeH - reservedBelowTimer;
    final widthCap = viewportW - 24;
    final heroExtent = (widthCap < heightCap ? widthCap : heightCap)
        .clamp(140.0, 380.0)
        .toDouble();

    final label = round.isActive ? l10n.gameTimeRemaining : l10n.gameRoundEnded;
    final roundLabel = l10n.gameRoundXOfY(round.index, widget.game.totalRounds);

    return CustomScrollView(
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
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
            child: Column(
              children: [
                asyncRole.when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.lime),
                    ),
                  ),
                  error: (_, _) => const RoleCard(role: null),
                  data: (role) => RoleCard(role: role),
                ),
                if (widget.isOwner) ...[
                  const SizedBox(height: 12),
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
                    label: Text(l10n.gameCtaEndRound),
                  ),
                ],
                const Spacer(),
                ScrollHint(
                  onTap: _scrollToLocations,
                  opacity: 1.0,
                  label: l10n.gameScrollHintLocations,
                ),
              ],
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
                  l10n.gameLocationsEyebrow,
                  style: AppTypography.mono(
                    size: 11,
                    letterSpacing: 2,
                    color: AppColors.paperFaint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.gameLocationsHint,
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
            padding: EdgeInsets.fromLTRB(20, 0, 20, 28 + bottomInset),
            sliver: SliverLocationGrid(board: board),
          ),
        ),
      ],
    );
  }
}

Future<bool> _confirmLeave(
  BuildContext context, {
  required bool isOwner,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.inkRaised,
      title: Text(l10n.gameLeaveDialogTitle),
      content: Text(
        isOwner
            ? l10n.gameLeaveDialogBodyOwner
            : l10n.gameLeaveDialogBodyPlayer,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.gameLeaveStay),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.signalRed),
          child: Text(l10n.gameLeaveLeave),
        ),
      ],
    ),
  );
  return result ?? false;
}
