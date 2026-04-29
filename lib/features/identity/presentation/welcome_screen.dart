import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/convex_config.dart';
import '../../../core/convex/convex_bootstrap.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configured =
        AppConvexConfig.isConfigured && ConvexBootstrap.isInitialized;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: AppColors.ink),
          ),
          const Positioned.fill(child: GrainOverlay()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Eyebrow(text: 'A PARTY GAME'),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _intro,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _intro,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: Text(
                        'Where am\nI?',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 76,
                          height: 0.95,
                          color: AppColors.paper,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Everyone shares a secret location.\nOne of you doesn\'t. Find them — or blend in.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.paperMuted,
                    ),
                  ),
                  const Spacer(),
                  if (!configured)
                    _ConfigBanner()
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go(AppRoute.home),
                          child: const Text('GET STARTED'),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => context.push(AppRoute.howToPlay),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'HOW TO PLAY',
                                style: AppTypography.mono(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  letterSpacing: 2.2,
                                  color: AppColors.lime,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.lime,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '3 to 12 players. No accounts. Pass-and-play friendly.',
                          textAlign: TextAlign.center,
                          style: AppTypography.mono(
                            size: 11,
                            weight: FontWeight.w500,
                            letterSpacing: 1.4,
                            color: AppColors.paperFaint,
                          ),
                        ),
                      ],
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

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 2,
          color: AppColors.lime,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppTypography.mono(
            size: 11,
            weight: FontWeight.w600,
            letterSpacing: 2.2,
            color: AppColors.lime,
          ),
        ),
      ],
    );
  }
}

class _ConfigBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'CONVEX_URL not set',
                style: AppTypography.mono(
                  size: 12,
                  weight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Provision a Convex deployment, then run:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.paperMuted),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inkOutline),
            ),
            child: Text(
              'flutter run --dart-define=CONVEX_URL=https://your.convex.cloud',
              style: AppTypography.mono(
                size: 11,
                weight: FontWeight.w500,
                color: AppColors.paper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
