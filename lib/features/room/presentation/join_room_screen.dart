import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/identity_storage.dart';
import '../../../core/theme/skin_backdrop.dart';
import '../../../core/theme/skin_context.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../identity/presentation/widgets/language_button.dart';
import '../data/room_providers.dart';
import '../domain/room.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  late final TextEditingController _nameCtrl;
  bool _busy = false;
  String? _error;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: IdentityStorage.instance.lastDisplayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _nameValid {
    final t = _nameCtrl.text.trim();
    return t.isNotEmpty && t.length <= 24;
  }

  Future<void> _join() async {
    if (!_nameValid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final name = _nameCtrl.text.trim();
    await IdentityStorage.instance.setLastDisplayName(name);
    try {
      final repo = ref.read(roomRepositoryProvider);
      final joined = await repo.joinRoom(
        code: widget.code,
        displayName: name,
      );
      await Haptics.success();
      if (!mounted) return;
      context.go(AppRoute.lobbyFor(joined));
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.localizedMessage(context));
      await Haptics.warning();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _maybeFastPathToLobby(Room room) {
    if (_redirected) return;
    final myToken = IdentityStorage.instance.clientToken;
    final alreadyMember = room.players.any((p) => p.clientToken == myToken);
    if (!alreadyMember) return;
    if (room.status != RoomStatus.lobby) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRoute.lobbyFor(room.code));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final asyncRoom = ref.watch(roomStreamProvider(widget.code));

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SkinBackdrop()),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (ctx, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(eyebrow: l10n.joinScreenEyebrow),
                            const SizedBox(height: 16),
                            asyncRoom.when(
                              loading: () => _PreviewCard(
                                code: widget.code,
                                child: Text(
                                  l10n.joinScreenLoading,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.skin.paperFaint,
                                  ),
                                ),
                              ),
                              error: (e, _) => _PreviewCard(
                                code: widget.code,
                                child: Text(
                                  l10n.joinScreenErrorNotFound(widget.code),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.skin.danger,
                                  ),
                                ),
                              ),
                              data: (room) {
                                if (room == null) {
                                  return _PreviewCard(
                                    code: widget.code,
                                    child: Text(
                                      l10n.joinScreenErrorNotFound(widget.code),
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: context.skin.danger,
                                          ),
                                    ),
                                  );
                                }
                                _maybeFastPathToLobby(room);
                                return _PreviewCard(
                                  code: room.code,
                                  child: _RoomDetails(room: room, l10n: l10n),
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            Text(
                              l10n.joinScreenTitle,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: context.skin.paper,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.joinScreenSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.skin.paperFaint,
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _nameCtrl,
                              maxLength: 24,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (asyncRoom.valueOrNull?.status ==
                                    RoomStatus.lobby) {
                                  _join();
                                }
                              },
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: context.skin.paper,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.homeCodenameHint,
                                counterText: '',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 24),
                            _JoinCta(
                              busy: _busy,
                              nameValid: _nameValid,
                              name: _nameCtrl.text.trim(),
                              roomState: asyncRoom,
                              onJoin: _join,
                              l10n: l10n,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.skin.danger,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => context.go(AppRoute.home),
                              child: Text(
                                l10n.joinScreenCtaBackHome,
                                style: context.skin.monoStyle(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: context.skin.paperMuted,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.eyebrow});
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go(AppRoute.home),
          icon: Icon(Icons.arrow_back, color: context.skin.paper),
        ),
        const SizedBox(width: 4),
        Text(
          eyebrow,
          style: context.skin.monoStyle(
            size: 11,
            weight: FontWeight.w600,
            letterSpacing: 2.4,
            color: context.skin.paperMuted,
          ),
        ),
        const Spacer(),
        const LanguageButton(),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.code, required this.child});
  final String code;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.skin.inkRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.skin.inkOutline),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        children: [
          Text(
            code,
            textAlign: TextAlign.center,
            style: context.skin.monoStyle(
              size: 38,
              weight: FontWeight.w700,
              letterSpacing: 14,
              color: context.skin.paper,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RoomDetails extends StatelessWidget {
  const _RoomDetails({required this.room, required this.l10n});
  final Room room;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hostName = room.players.isEmpty ? null : room.players.first.displayName;
    final hostLine = hostName == null
        ? l10n.joinScreenAnonymousHost
        : l10n.joinScreenHostLine(hostName);
    return Column(
      children: [
        Text(
          hostLine,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: context.skin.paper),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.joinScreenPlayerCount(room.players.length),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.skin.paperFaint,
          ),
        ),
        const SizedBox(height: 12),
        _StatusPill(status: room.status, l10n: l10n),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.l10n});
  final RoomStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RoomStatus.lobby => (l10n.joinScreenStatusLobby, context.skin.accent),
      RoomStatus.inGame => (l10n.joinScreenStatusInGame, context.skin.secondary),
      RoomStatus.ended => (l10n.joinScreenStatusEnded, context.skin.paperFaint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: context.skin.monoStyle(
          size: 10,
          weight: FontWeight.w700,
          letterSpacing: 2,
          color: color,
        ),
      ),
    );
  }
}

class _JoinCta extends StatelessWidget {
  const _JoinCta({
    required this.busy,
    required this.nameValid,
    required this.name,
    required this.roomState,
    required this.onJoin,
    required this.l10n,
  });

  final bool busy;
  final bool nameValid;
  final String name;
  final AsyncValue<Room?> roomState;
  final VoidCallback onJoin;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final room = roomState.valueOrNull;
    final loaded = !roomState.isLoading;
    final canJoin =
        !busy && nameValid && room != null && room.status == RoomStatus.lobby;

    String label;
    if (busy) {
      label = l10n.joinScreenCtaBusy;
    } else if (!nameValid) {
      label = l10n.joinScreenCtaJoinNoName;
    } else {
      label = l10n.joinScreenCtaJoin(name.toUpperCase());
    }

    String? footnote;
    if (!nameValid) {
      footnote = l10n.homeHintNeedCodename;
    } else if (loaded && room == null) {
      // Will be handled by the preview card error too, but reinforce here.
      footnote = null;
    } else if (room?.status == RoomStatus.inGame) {
      footnote = l10n.joinScreenErrorInGame;
    } else if (room?.status == RoomStatus.ended) {
      footnote = l10n.joinScreenErrorEnded;
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: canJoin ? onJoin : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (footnote != null) ...[
          const SizedBox(height: 10),
          Text(
            footnote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.skin.paperFaint,
            ),
          ),
        ],
      ],
    );
  }
}
