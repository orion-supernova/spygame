import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/convex_config.dart';
import '../../../core/convex/convex_bootstrap.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/language_button.dart';

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
    final l10n = AppLocalizations.of(context);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Eyebrow(text: l10n.welcomeEyebrow),
                      const LanguageButton(),
                    ],
                  ),
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
                        l10n.welcomeTitle,
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
                    l10n.welcomeSubtitle,
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
                          child: Text(l10n.welcomeCtaGetStarted),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoute.howToPlay),
                              child: Text(
                                l10n.welcomeCtaHowToPlay,
                                style: AppTypography.mono(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  letterSpacing: 2.2,
                                  color: AppColors.lime,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              color: AppColors.inkOutline,
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoute.marketplace),
                              child: Text(
                                l10n.welcomeCtaMarketplace,
                                style: AppTypography.mono(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  letterSpacing: 2.2,
                                  color: AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.welcomeFootnote,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.welcomeConfigBannerTitle,
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
            l10n.welcomeConfigBannerBody,
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
