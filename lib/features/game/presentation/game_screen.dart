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
import 'countdown_ring.dart';
import 'location_grid.dart';
import 'role_card.dart';

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
      notificationId: round.index, // small int per round index is fine
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

    // On lifecycle resume, opportunistically check round-end and re-arm
    // notification scheduling in case the round changed while away.
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
                  return const Center(
                    child: Text('Room ended.'),
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
    final round = room.currentRound;
    final game = room.currentGame;
    if (round == null || game == null) {
      return const Center(child: Text('Setting up round…'));
    }

    final isOwner = room.isOwner(myToken);
    final totalMs = (round.endsAtMs - round.startedAtMs).clamp(1, 1 << 30);
    final args = CountdownArgs(
      endsAtServerMs: round.endsAtMs,
      totalMs: totalMs,
    );
    final countdown = ref.watch(countdownControllerProvider(args));
    final asyncRole = ref.watch(myRoleProvider(round.id));
    final asyncBoard = ref.watch(locationsBoardProvider(room.code));

    onSecondHaptic(countdown.seconds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () async {
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
              'ROUND ${round.index} OF ${game.totalRounds}',
              style: AppTypography.mono(
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 2.2,
                color: AppColors.paperFaint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CountdownRing(
            progress: countdown.progress,
            seconds: countdown.seconds,
            totalSeconds: (totalMs / 1000).round(),
            label: round.isActive ? 'TIME REMAINING' : 'ROUND ENDED',
          ),
        ),
        const SizedBox(height: 24),
        asyncRole.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(
                child: CircularProgressIndicator(color: AppColors.lime)),
          ),
          error: (_, __) => const RoleCard(role: null),
          data: (role) => RoleCard(role: role),
        ),
        const SizedBox(height: 24),
        if (isOwner) ...[
          OutlinedButton.icon(
            onPressed: round.isActive
                ? () async {
                    await Haptics.warning();
                    await ref
                        .read(roomRepositoryProvider)
                        .endRoundManual(code: room.code);
                  }
                : null,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('END ROUND NOW'),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'LOCATIONS',
          style: AppTypography.mono(
            size: 11,
            weight: FontWeight.w600,
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
                child: CircularProgressIndicator(color: AppColors.lime)),
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
