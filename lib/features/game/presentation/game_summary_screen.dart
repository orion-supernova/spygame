import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/skin_backdrop.dart';
import '../../../core/theme/skin_context.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../room/data/room_providers.dart';

class GameSummaryScreen extends ConsumerWidget {
  const GameSummaryScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRoom = ref.watch(roomStreamProvider(code));
    final l10n = AppLocalizations.of(context);
    final skin = context.skin;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SkinBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.summaryEyebrow,
                    style: skin.monoStyle(
                      size: 11,
                      letterSpacing: 2.4,
                      color: skin.paperFaint,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.summaryHeadline,
                    style:
                        Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: skin.paper,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.summaryRoomClosed(code),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: skin.paperMuted,
                        ),
                  ),
                  const Spacer(),
                  asyncRoom.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (_) => const SizedBox.shrink(),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoute.home),
                    child: Text(l10n.summaryCtaNewGame),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
