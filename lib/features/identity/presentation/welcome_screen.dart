import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/convex_config.dart';
import '../../../core/config/dev_mode.dart';
import '../../../core/convex/convex_bootstrap.dart';
import '../../../core/convex/convex_client_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/skin_backdrop.dart';
import '../../../core/theme/skin_context.dart';
import '../../../core/utils/haptics.dart';
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
          const Positioned.fill(child: SkinBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          color: context.skin.paper,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.welcomeSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: context.skin.paperMuted,
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
                                style: context.skin.monoStyle(
                                  size: 11,
                                  letterSpacing: 2.2,
                                  color: context.skin.accent,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              color: context.skin.inkOutline,
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoute.marketplace),
                              child: Text(
                                l10n.welcomeCtaMarketplace,
                                style: context.skin.monoStyle(
                                  size: 11,
                                  letterSpacing: 2.2,
                                  color: context.skin.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.welcomeFootnote,
                          textAlign: TextAlign.center,
                          style: context.skin.monoStyle(
                            size: 11,
                            weight: FontWeight.w500,
                            letterSpacing: 1.4,
                            color: context.skin.paperFaint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const _VersionLabel(),
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
          color: context.skin.accent,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: context.skin.monoStyle(
            size: 11,
            letterSpacing: 2.2,
            color: context.skin.accent,
          ),
        ),
      ],
    );
  }
}

/// Version footer. Looks inert, but the version *number* (not the "Version:"
/// label) is a hidden 10-tap gesture: ten taps within the reset window open a
/// code prompt; a correct code (verified server-side via `dev:verifyDevCode`)
/// unlocks runtime [devModeProvider] so mock purchases and other dev tools
/// work even on an App Store build. Tapping again while unlocked offers to
/// turn it back off. The number carries a "• DEV" marker while active.
class _VersionLabel extends ConsumerStatefulWidget {
  const _VersionLabel();

  @override
  ConsumerState<_VersionLabel> createState() => _VersionLabelState();
}

class _VersionLabelState extends ConsumerState<_VersionLabel> {
  static const _tapsToUnlock = 10;
  static const _resetWindow = Duration(seconds: 2);

  int _taps = 0;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onNumberTap() {
    _resetTimer?.cancel();
    _resetTimer = Timer(_resetWindow, () => _taps = 0);
    _taps++;
    if (_taps >= _tapsToUnlock) {
      _taps = 0;
      _resetTimer?.cancel();
      _handleUnlockGesture();
    }
  }

  Future<void> _handleUnlockGesture() async {
    if (ref.read(devModeProvider)) {
      final disable = await _confirmDisable();
      if (disable == true) {
        await ref.read(devModeProvider.notifier).disable();
        await Haptics.medium();
        _toast('Dev mode disabled');
      }
      return;
    }
    final code = await _promptForCode();
    if (code == null || code.isEmpty) return;
    await _verifyAndEnable(code);
  }

  Future<void> _verifyAndEnable(String code) async {
    var ok = false;
    try {
      await ConvexBootstrap.ensureReady();
      final raw = await ref
          .read(convexClientProvider)
          .query('dev:verifyDevCode', {'code': code});
      ok = jsonDecode(raw) == true;
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      await ref.read(devModeProvider.notifier).enable();
      await Haptics.success();
      _toast('Dev mode unlocked');
    } else {
      await Haptics.warning();
      _toast('Invalid code');
    }
  }

  Future<String?> _promptForCode() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Developer mode'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter code'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDisable() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Developer mode'),
        content: const Text('Dev mode is on. Turn it off?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep on'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final devOn = ref.watch(devModeProvider);
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) {
          return const SizedBox.shrink();
        }
        final full = l10n.welcomeVersion(info.version);
        final idx = full.indexOf(info.version);
        final prefix = idx >= 0 ? full.substring(0, idx) : full;
        final suffix = idx >= 0 ? full.substring(idx + info.version.length) : '';
        final style = context.skin.monoStyle(
          size: 10,
          weight: FontWeight.w500,
          letterSpacing: 1.2,
          color: context.skin.paperFaint,
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefix.isNotEmpty) Text(prefix, style: style),
            // Only the number is the hidden tap target — not the label.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onNumberTap,
              child: Text(info.version, style: style),
            ),
            if (suffix.isNotEmpty) Text(suffix, style: style),
            if (devOn)
              Text(' • DEV', style: style.copyWith(color: context.skin.accent)),
          ],
        );
      },
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
        color: context.skin.inkRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.skin.secondary.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: context.skin.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.welcomeConfigBannerTitle,
                style: context.skin.monoStyle(
                  size: 12,
                  letterSpacing: 1.2,
                  color: context.skin.secondary,
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
                ?.copyWith(color: context.skin.paperMuted),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.skin.ink,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.skin.inkOutline),
            ),
            child: Text(
              'flutter run --dart-define=CONVEX_URL=https://your.convex.cloud',
              style: context.skin.monoStyle(
                size: 11,
                weight: FontWeight.w500,
                color: context.skin.paper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
