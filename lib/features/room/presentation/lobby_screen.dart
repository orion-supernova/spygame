import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/convex/server_time_provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/notifications/round_end_notifier.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/identity_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/room_providers.dart';
import '../domain/room.dart';
import 'widgets/config_panel.dart';
import 'widgets/player_tile.dart';
import 'widgets/ready_button.dart';
import 'widgets/room_code_chip.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  Timer? _heartbeat;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Lazy permission ask once we're inside a room.
    // ignore: discarded_futures
    RoundEndNotifier.instance.requestPermissionIfNeeded();
    // ignore: discarded_futures
    Future.microtask(
      () => ref.read(serverTimeOffsetProvider.notifier).refresh(),
    );
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      // ignore: discarded_futures
      ref.read(roomRepositoryProvider).heartbeat(code: widget.code);
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    super.dispose();
  }

  Future<void> _toggleReady(bool current) async {
    await Haptics.selection();
    try {
      await ref.read(serverTimeOffsetProvider.notifier).refresh();
      await ref
          .read(roomRepositoryProvider)
          .setReady(code: widget.code, ready: !current);
    } on AppException catch (e) {
      if (!mounted) return;
      _showError(e.localizedMessage(context));
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await ref.read(serverTimeOffsetProvider.notifier).refresh();
      await ref.read(roomRepositoryProvider).startGame(code: widget.code);
      await Haptics.success();
    } on AppException catch (e) {
      if (mounted) _showError(e.localizedMessage(context));
      await Haptics.warning();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    await ref.read(roomRepositoryProvider).leaveRoom(code: widget.code);
    if (!mounted) return;
    context.go(AppRoute.home);
  }

  Future<void> _share() async {
    // iOS requires a non-zero `sharePositionOrigin` rect within the source
    // view's coordinate space (iPad popover anchor; modern iOS enforces it
    // on iPhone too). Capture the box BEFORE the await to avoid using
    // `context` across an async gap.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final l10n = AppLocalizations.of(context);
    await Haptics.light();
    await Share.share(
      l10n.lobbyShareMessage(widget.code),
      subject: l10n.lobbyShareSubject(widget.code),
      sharePositionOrigin: origin,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onConfigChanged(GameConfig next) async {
    try {
      await ref
          .read(roomRepositoryProvider)
          .updateConfig(code: widget.code, config: next);
      await Haptics.selection();
    } on AppException catch (e) {
      if (!mounted) return;
      _showError(e.localizedMessage(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRoom = ref.watch(roomStreamProvider(widget.code));
    final myToken = IdentityStorage.instance.clientToken;

    ref.listen(roomStreamProvider(widget.code), (prev, next) {
      next.whenData((room) {
        if (room == null) return;
        ref
            .read(serverTimeOffsetProvider.notifier)
            .observeServerNow(room.serverNowMs);
        if (room.status == RoomStatus.inGame && mounted) {
          context.go(AppRoute.gameFor(room.code));
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
              error: (e, _) => _ErrorView(
                message: e is AppException
                    ? e.localizedMessage(context)
                    : e.toString(),
                onLeave: _leave,
              ),
              data: (room) {
                if (room == null) {
                  return _ErrorView(
                    message: AppLocalizations.of(context).lobbyErrorRoomGone,
                    onLeave: _leave,
                  );
                }
                return _LobbyBody(
                  room: room,
                  myToken: myToken,
                  busy: _busy,
                  onToggleReady: () =>
                      _toggleReady(room.playerFor(myToken)?.isReady ?? false),
                  onStart: _start,
                  onShare: _share,
                  onLeave: _leave,
                  onConfigChanged: _onConfigChanged,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyBody extends StatelessWidget {
  const _LobbyBody({
    required this.room,
    required this.myToken,
    required this.busy,
    required this.onToggleReady,
    required this.onStart,
    required this.onShare,
    required this.onLeave,
    required this.onConfigChanged,
  });

  final Room room;
  final String myToken;
  final bool busy;
  final VoidCallback onToggleReady;
  final VoidCallback onStart;
  final VoidCallback onShare;
  final VoidCallback onLeave;
  final ValueChanged<GameConfig> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final isOwner = room.isOwner(myToken);
    final me = room.playerFor(myToken);
    final canStart = isOwner && room.allReady && room.players.length >= 3;
    final l10n = AppLocalizations.of(context);

    final bottomPanelBuffer = isOwner ? 220.0 : 110.0;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onLeave,
                        icon: const Icon(Icons.close, color: AppColors.paper),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.lobbyEyebrow,
                        style: AppTypography.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 2.4,
                          color: AppColors.paperFaint,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onShare,
                        icon: const Icon(
                          Icons.ios_share,
                          color: AppColors.paper,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    children: [
                      RoomCodeChip(code: room.code),
                      const SizedBox(height: 12),
                      Text(
                        l10n.lobbyShareHint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.paperFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        l10n.lobbyPlayersLabel,
                        style: AppTypography.mono(
                          size: 11,
                          weight: FontWeight.w600,
                          letterSpacing: 2,
                          color: AppColors.paperFaint,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.lobbyPlayersCount(room.players.length),
                        style: AppTypography.mono(
                          size: 11,
                          weight: FontWeight.w500,
                          letterSpacing: 1.4,
                          color: AppColors.paperFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemBuilder: (context, i) {
                    final p = room.players[i];
                    return PlayerTile(
                      player: p,
                      isSelf: p.clientToken == myToken,
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: room.players.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: ConfigPanel(
                    config: room.config,
                    editable: isOwner,
                    onChanged: onConfigChanged,
                  ),
                ),
              ),
              // Spacer so the last bit of content can scroll above the
              // pinned action panel below.
              SliverToBoxAdapter(child: SizedBox(height: bottomPanelBuffer)),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fade signals that scrollable content extends below.
              IgnorePointer(
                child: Container(
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x000B0D12), AppColors.ink],
                    ),
                  ),
                ),
              ),
              Container(
                color: AppColors.ink,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    if (me != null)
                      ReadyButton(ready: me.isReady, onToggle: onToggleReady),
                    if (isOwner) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: canStart && !busy ? onStart : null,
                        child: Text(
                          busy ? l10n.lobbyCtaStarting : l10n.lobbyCtaStart,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        canStart
                            ? l10n.lobbyStatusAllReady
                            : room.players.length < 3
                            ? l10n.lobbyStatusNeedPlayers
                            : l10n.lobbyStatusWaitingReady,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.paperFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onLeave});
  final String message;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.report_gmailerrorred,
            color: AppColors.signalRed,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          OutlinedButton(
            onPressed: onLeave,
            child: Text(AppLocalizations.of(context).lobbyCtaGoHome),
          ),
        ],
      ),
    );
  }
}
