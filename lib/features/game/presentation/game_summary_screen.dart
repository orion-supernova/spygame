import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../room/data/room_providers.dart';

class GameSummaryScreen extends ConsumerWidget {
  const GameSummaryScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRoom = ref.watch(roomStreamProvider(code));
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.ink)),
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.summaryEyebrow,
                    style: AppTypography.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      letterSpacing: 2.4,
                      color: AppColors.paperFaint,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.summaryHeadline,
                    style:
                        Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.paper,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.summaryRoomClosed(code),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.paperMuted,
                        ),
                  ),
                  const Spacer(),
                  asyncRoom.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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
