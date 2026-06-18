import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/skin_backdrop.dart';
import '../../../core/theme/skin_context.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../game/presentation/countdown_ring.dart';

class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen>
    with TickerProviderStateMixin {
  static const _total = 6;

  final PageController _pages = PageController();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  )..forward();

  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    Haptics.selection();
    setState(() => _index = i);
    // Don't reset `_reveal` here — it would flash every card's contents to
    // opacity 0 (including the page that just slid into view) and fade
    // them back up, which reads as a flicker. The PageView's horizontal
    // slide is the page-to-page transition; the staggered fade is only
    // for the initial entrance.
  }

  void _jumpTo(int i) {
    if (i == _index) return;
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _close({bool success = false}) async {
    await (success ? Haptics.success() : Haptics.light());
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _total - 1;
    final l10n = AppLocalizations.of(context);

    final cards = <_Card>[
      _Card(
        step: l10n.htpStep1,
        heading: l10n.htpHeading1,
        body: l10n.htpBody1,
        visual: const _DotGridVisual(),
      ),
      _Card(
        step: l10n.htpStep2,
        heading: l10n.htpHeading2,
        body: l10n.htpBody2,
        visual: const _MockRoleCard(isSpy: false),
      ),
      _Card(
        step: l10n.htpStep3,
        heading: l10n.htpHeading3,
        body: l10n.htpBody3,
        visual: const _MockRoleCard(isSpy: true),
      ),
      _Card(
        step: l10n.htpStep4,
        heading: l10n.htpHeading4,
        body: l10n.htpBody4,
        visual: const _AskVisual(),
      ),
      _Card(
        step: l10n.htpStep5,
        heading: l10n.htpHeading5,
        body: l10n.htpBody5,
        visual: const _SpyCallVisual(),
      ),
      _Card(
        step: l10n.htpStep6,
        heading: l10n.htpHeading6,
        body: l10n.htpBody6,
        visual: const _VoteVisual(),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SkinBackdrop()),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  index: _index,
                  total: _total,
                  isLast: isLast,
                  onJump: _jumpTo,
                  onSkip: () => _close(),
                  onClose: () => _close(),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _total,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) => _CardView(
                      card: cards[i],
                      reveal: _reveal,
                      isActive: i == _index,
                    ),
                  ),
                ),
                _BottomBar(
                  isLast: isLast,
                  onNext: () {
                    _pages.nextPage(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  onDone: () => _close(success: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card {
  const _Card({
    required this.step,
    required this.heading,
    required this.body,
    required this.visual,
  });

  final String step;
  final String heading;
  final String body;
  final Widget visual;
}

class _CardView extends StatelessWidget {
  const _CardView({
    required this.card,
    required this.reveal,
    required this.isActive,
  });

  final _Card card;
  final Animation<double> reveal;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visualAnim = CurvedAnimation(
      parent: reveal,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    final eyebrowAnim = CurvedAnimation(
      parent: reveal,
      curve: const Interval(0.18, 0.55, curve: Curves.easeOutCubic),
    );
    final headingAnim = CurvedAnimation(
      parent: reveal,
      curve: const Interval(0.28, 0.75, curve: Curves.easeOutCubic),
    );
    final bodyAnim = CurvedAnimation(
      parent: reveal,
      curve: const Interval(0.42, 1.0, curve: Curves.easeOutCubic),
    );

    Widget reveal0(Animation<double> a, Widget child) {
      return FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: reveal0(
                      visualAnim,
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.94, end: 1.0)
                            .animate(visualAnim),
                        // Isolate the looping visual's repaints from the
                        // static heading/body/grain layers.
                        child: RepaintBoundary(child: card.visual),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  reveal0(eyebrowAnim, _Eyebrow(text: card.step)),
                  const SizedBox(height: 14),
                  reveal0(
                    headingAnim,
                    Text(
                      card.heading,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 52,
                        height: 0.98,
                        color: context.skin.paper,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  reveal0(
                    bodyAnim,
                    Text(
                      card.body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: context.skin.paperMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.total,
    required this.isLast,
    required this.onJump,
    required this.onSkip,
    required this.onClose,
  });

  final int index;
  final int total;
  final bool isLast;
  final ValueChanged<int> onJump;
  final VoidCallback onSkip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          for (int i = 0; i < total; i++) ...[
            _ProgressDot(
              active: i == index,
              onTap: () => onJump(i),
            ),
            if (i < total - 1) const SizedBox(width: 6),
          ],
          const Spacer(),
          if (isLast)
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: context.skin.paper),
              tooltip: AppLocalizations.of(context).htpClose,
            )
          else
            TextButton(
              onPressed: onSkip,
              child: Text(
                AppLocalizations.of(context).htpSkip,
                style: context.skin.monoStyle(
                  size: 11,
                  letterSpacing: 2.2,
                  color: context.skin.paperMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? context.skin.accent : context.skin.inkOutline,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isLast,
    required this.onNext,
    required this.onDone,
  });

  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      child: SizedBox(
        height: 56,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: isLast
              ? SizedBox(
                  key: const ValueKey('done'),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDone,
                    child: Text(AppLocalizations.of(context).htpDone),
                  ),
                )
              : Row(
                  key: const ValueKey('next'),
                  children: [
                    const _SwipeHint(),
                    const Spacer(),
                    TextButton(
                      onPressed: onNext,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context).htpNext,
                            style: context.skin.monoStyle(
                              size: 11,
                              letterSpacing: 2.2,
                              color: context.skin.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: context.skin.accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SwipeHint extends StatefulWidget {
  const _SwipeHint();

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _bob, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, _) {
        final dx = curved.value * 6.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).htpSwipe,
                style: context.skin.monoStyle(
                  size: 11,
                  weight: FontWeight.w500,
                  letterSpacing: 2.2,
                  color: context.skin.paperFaint,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.skin.paperFaint.withValues(alpha: 0.8),
              ),
            ],
          ),
        );
      },
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
        Container(width: 28, height: 2, color: context.skin.accent),
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

class _DotGridVisual extends StatefulWidget {
  const _DotGridVisual();

  @override
  State<_DotGridVisual> createState() => _DotGridVisualState();
}

class _DotGridVisualState extends State<_DotGridVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const spyIndex = 4; // center cell of 3×3
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (_, _) {
          final t = _loop.value;

          Widget dot(int i) {
            if (i != spyIndex) {
              // Each civilian dot breathes on its own phase — a crowd
              // of people, all alive, all slightly out of sync.
              final wave = math.sin(2 * math.pi * t + i * 0.9);
              return Center(
                child: Transform.scale(
                  scale: 1 + 0.18 * wave,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: context.skin.accent
                          .withValues(alpha: 0.85 + 0.15 * wave),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }
            // The spy: a radar ping — the ripple expands outward and
            // fades, twice per loop, while the dot itself beats.
            final tp = (t * 2) % 1.0;
            return Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 20 + 30 * tp,
                    height: 20 + 30 * tp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.skin.danger
                            .withValues(alpha: 0.55 * (1 - tp)),
                        width: 2,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 1 + 0.15 * (1 - tp) * math.sin(math.pi * tp),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: context.skin.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              for (int row = 0; row < 3; row++)
                Expanded(
                  child: Row(
                    children: [
                      for (int col = 0; col < 3; col++)
                        Expanded(child: dot(row * 3 + col)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MockRoleCard extends StatefulWidget {
  const _MockRoleCard({required this.isSpy});
  final bool isSpy;

  @override
  State<_MockRoleCard> createState() => _MockRoleCardState();
}

class _MockRoleCardState extends State<_MockRoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isSpy = widget.isSpy;
    final accent = isSpy ? context.skin.danger : context.skin.accent;
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        final t = _loop.value;
        final breathe = 0.5 + 0.5 * math.sin(2 * math.pi * t);
        return Container(
          width: 280,
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSpy
                ? context.skin.danger.withValues(alpha: 0.12)
                : context.skin.inkRaised,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent, width: 1.5),
            boxShadow: isSpy
                ? [
                    BoxShadow(
                      color: context.skin.danger
                          .withValues(alpha: 0.10 + 0.14 * breathe),
                      blurRadius: 24 + 12 * breathe,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status dot blinks like a rec light.
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.4 + 0.6 * breathe),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.roleYourRole,
                    style: context.skin.monoStyle(
                      size: 11,
                      letterSpacing: 2.2,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isSpy) ...[
                _WaveText(
                  text: l10n.roleTheSpy,
                  t: t,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: context.skin.danger,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                _ScrambleText(
                  text: l10n.htpVisualLocationUnknown,
                  t: t,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.skin.paper,
                  ),
                ),
              ] else ...[
                _WaveText(
                  text: l10n.htpVisualRoleExample,
                  t: t,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: context.skin.paper,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.roleFrontAt,
                  style: context.skin.monoStyle(
                    size: 11,
                    letterSpacing: 2.2,
                    color: context.skin.paperFaint,
                  ),
                ),
                const SizedBox(height: 4),
                // The location shimmers — it's the prize.
                Opacity(
                  opacity: 0.72 + 0.28 * breathe,
                  child: Text(
                    l10n.htpVisualLocationExample,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: context.skin.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Letter-by-letter traveling bump: one wave sweeps across the text,
/// then rests until the next loop. Driven by the parent's `t` (0..1).
class _WaveText extends StatelessWidget {
  const _WaveText({required this.text, required this.t, this.style});

  final String text;
  final double t;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    // The bump travels past the last letter during the first 55% of the
    // loop; the rest is a pause.
    final span = chars.length + 3.0;
    final pos = t < 0.55 ? (t / 0.55) * span - 1.5 : -10.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < chars.length; i++)
          Transform.translate(
            offset: Offset(0, -5 * _bump(pos, i)),
            child: Text(chars[i], style: style),
          ),
      ],
    );
  }

  static double _bump(double pos, int i) {
    final d = (pos - i).abs();
    if (d >= 2) return 0;
    return 0.5 + 0.5 * math.cos(math.pi * d / 2);
  }
}

/// Spy decoder effect: the last word of the string flickers through
/// glyphs and resolves left-to-right each loop. Driven by parent `t`.
class _ScrambleText extends StatelessWidget {
  const _ScrambleText({required this.text, required this.t, this.style});

  static const _glyphs = r'@#%&?*+=';

  final String text;
  final double t;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cut = text.lastIndexOf(' ') + 1;
    final prefix = text.substring(0, cut);
    final word = text.substring(cut);

    String shown = word;
    if (t < 0.4) {
      final resolved = ((t / 0.4) * word.length).floor();
      // Re-seed on a coarse step so the glyphs flicker ~12×/s instead
      // of every frame.
      final rnd = math.Random((t * 40).floor());
      final buf = StringBuffer();
      for (int i = 0; i < word.length; i++) {
        buf.write(
          i < resolved ? word[i] : _glyphs[rnd.nextInt(_glyphs.length)],
        );
      }
      shown = buf.toString();
    }
    return Text('$prefix$shown', style: style);
  }
}

/// Card 4 visual: a compact mock countdown chip ticking above a looping
/// chat demo that shows what round questions sound like.
class _AskVisual extends StatefulWidget {
  const _AskVisual();

  @override
  State<_AskVisual> createState() => _AskVisualState();
}

class _AskVisualState extends State<_AskVisual> with TickerProviderStateMixin {
  // Mock timer: five visible ticks (5:00 → 4:55), then a clean reset.
  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  // One full chat loop: exchange A, exchange B (with typing dots), reset.
  late final AnimationController _chat = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _countdown.dispose();
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _countdown,
            builder: (context, _) {
              final t = _countdown.value;
              // Step the digits once per controller-second; clamp so the
              // final frame (t == 1.0) doesn't flash a sixth tick before
              // the wrap snaps cleanly back to 5:00.
              final seconds = 300 - (t * 5).floor().clamp(0, 4);
              // The ring drains faster than the true 4s/300s ratio —
              // a proportional sweep would be invisible. This is a mock;
              // it just needs to read as "the timer is running".
              return CountdownChip(
                progress: 1 - 0.3 * t,
                seconds: seconds,
                label: AppLocalizations.of(context).htpVisualPerRound,
              );
            },
          ),
          const SizedBox(height: 18),
          _ChatExchange(chat: _chat),
        ],
      ),
    );
  }
}

/// Looping scripted Q&A: a good in-character answer, then the spy's
/// vague tell. Only one exchange is visible at a time.
class _ChatExchange extends StatelessWidget {
  const _ChatExchange({required this.chat});
  final Animation<double> chat;

  /// Eased 0..1 progress of `t` within the [start, end] slice of the loop.
  static double _seg(double t, double start, double end) {
    final raw = ((t - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 280,
      height: 168,
      child: AnimatedBuilder(
        animation: chat,
        builder: (context, _) {
          final t = chat.value;

          // Exchange A: in 0.06–0.26, out 0.42–0.50.
          final aOut = 1 - _seg(t, 0.42, 0.50);
          final q1 = _seg(t, 0.06, 0.16) * aOut;
          final a1 = _seg(t, 0.16, 0.26) * aOut;

          // Exchange B: in 0.50–0.72, out 0.90–1.0. The spy "types"
          // (dots) before the hesitant answer replaces them.
          final bOut = 1 - _seg(t, 0.90, 1.0);
          final q2 = _seg(t, 0.50, 0.58) * bOut;
          final dots = _seg(t, 0.58, 0.64) * (1 - _seg(t, 0.64, 0.68));
          final a2 = _seg(t, 0.68, 0.74) * bOut;

          final showA = q1 > 0 || a1 > 0;

          Widget slot({
            required double reveal,
            required bool fromLeft,
            required Widget child,
          }) {
            if (reveal <= 0) return const SizedBox.shrink();
            return Opacity(
              opacity: reveal,
              child: Transform.translate(
                offset: Offset((fromLeft ? -14.0 : 14.0) * (1 - reveal), 0),
                child: child,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: showA
                ? [
                    slot(
                      reveal: q1,
                      fromLeft: true,
                      child: _Bubble(
                        name: l10n.htpAskNamePlayer,
                        text: l10n.htpAskQ1,
                        fromLeft: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    slot(
                      reveal: a1,
                      fromLeft: false,
                      child: _Bubble(
                        name: l10n.htpAskNameYou,
                        text: l10n.htpAskA1,
                        fromLeft: false,
                        accent: context.skin.accent,
                      ),
                    ),
                  ]
                : [
                    slot(
                      reveal: q2,
                      fromLeft: true,
                      child: _Bubble(
                        name: l10n.htpAskNamePlayer,
                        text: l10n.htpAskQ2,
                        fromLeft: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (a2 > 0)
                      slot(
                        reveal: a2,
                        fromLeft: false,
                        child: _Bubble(
                          name: l10n.htpAskNameSpy,
                          text: l10n.htpAskA2,
                          fromLeft: false,
                          accent: context.skin.danger,
                        ),
                      )
                    else
                      slot(
                        reveal: dots,
                        fromLeft: false,
                        child: const _TypingBubble(),
                      ),
                  ],
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.name,
    required this.text,
    required this.fromLeft,
    this.accent,
  });

  final String name;
  final String text;
  final bool fromLeft;

  /// Answer bubbles get a tinted fill + colored border; questions stay
  /// neutral. Null means neutral.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = this.accent;
    final labelColor = accent ?? context.skin.paperFaint;
    return Align(
      alignment: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 216),
        child: Column(
          crossAxisAlignment:
              fromLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
              child: Text(
                name,
                style: context.skin.monoStyle(
                  size: 9,
                  letterSpacing: 2,
                  color: labelColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accent == null
                    ? context.skin.inkRaised
                    : Color.alphaBlend(
                        accent.withValues(alpha: 0.12),
                        context.skin.inkRaised,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(fromLeft ? 4 : 16),
                  bottomRight: Radius.circular(fromLeft ? 16 : 4),
                ),
                border: Border.all(
                  color: accent?.withValues(alpha: 0.5) ?? context.skin.inkOutline,
                ),
              ),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.skin.paper,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The spy stalling: a right-side bubble with three faint dots.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.skin.inkRaised,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: context.skin.inkOutline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.skin.paperFaint
                      .withValues(alpha: i == 2 ? 0.5 : 0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card 5 visual: the spy's gambit. The spy's announcement bubble pops
/// in, then a "ONE GUESS" chip with a pinging target ring stamps below.
class _SpyCallVisual extends StatefulWidget {
  const _SpyCallVisual();

  @override
  State<_SpyCallVisual> createState() => _SpyCallVisualState();
}

class _SpyCallVisualState extends State<_SpyCallVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  static double _seg(double t, double start, double end) {
    final raw = ((t - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 280,
      height: 170,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final t = _loop.value;
          final out = 1 - _seg(t, 0.92, 1.0);
          final bubble = _seg(t, 0.04, 0.16) * out;
          final chip = _seg(t, 0.22, 0.34) * out;
          // Target ring pings twice while the chip is on screen.
          final ping = t > 0.34 && t < 0.86 ? ((t - 0.34) / 0.26) % 1.0 : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bubble > 0)
                Opacity(
                  opacity: bubble,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * bubble,
                    alignment: Alignment.centerRight,
                    child: _Bubble(
                      name: l10n.spyRevealNameEyebrow,
                      text: l10n.htpVisualSpyCall,
                      fromLeft: false,
                      accent: context.skin.danger,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (chip > 0)
                Opacity(
                  opacity: chip,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - chip)),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: context.skin.inkRaised,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: context.skin.inkOutline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Target: a dot with a pinging ring.
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 8 + 14 * ping,
                                    height: 8 + 14 * ping,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: context.skin.danger.withValues(
                                          alpha: 0.6 * (1 - ping),
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: context.skin.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.htpVisualOneGuess,
                              style: context.skin.monoStyle(
                                size: 13,
                                weight: FontWeight.w700,
                                letterSpacing: 3,
                                color: context.skin.paper,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Card 6 visual: time's up, vote. A chevron hops between suspects;
/// the accused dot gets a red ring. Captions carry the stakes.
class _VoteVisual extends StatefulWidget {
  const _VoteVisual();

  @override
  State<_VoteVisual> createState() => _VoteVisualState();
}

class _VoteVisualState extends State<_VoteVisual>
    with SingleTickerProviderStateMixin {
  static const _dots = 5;

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const slot = 48.0;
    const rowWidth = slot * _dots;
    return SizedBox(
      width: 280,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final t = _loop.value;
          // The accusation roams: dwell on each suspect, then slide to
          // the next. Visits dots 1, 3, 0, 2 across one loop.
          const order = [1, 3, 0, 2];
          final phase = t * order.length;
          final step = phase.floor() % order.length;
          final local = phase - phase.floor();
          final from = order[step].toDouble();
          final to = order[(step + 1) % order.length].toDouble();
          // Dwell for 70% of the step, glide for the rest.
          final glide = local < 0.7
              ? 0.0
              : Curves.easeInOutCubic.transform((local - 0.7) / 0.3);
          final target = from + (to - from) * glide;
          final bob = 3 * math.sin(2 * math.pi * t * 6);
          // The ring tightens onto the suspect while dwelling.
          final lock = local < 0.7 ? (local / 0.7).clamp(0.0, 1.0) : 1 - glide;

          return Column(
            children: [
              Text(
                l10n.htpVisualWhoIsSpy,
                style: context.skin.monoStyle(
                  size: 13,
                  weight: FontWeight.w700,
                  letterSpacing: 3,
                  color: context.skin.paper,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: rowWidth,
                height: 76,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The accusing chevron, hopping between suspects.
                    Positioned(
                      left: target * slot,
                      top: bob,
                      width: slot,
                      child: Center(
                        child: Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 34,
                          color: context.skin.danger,
                        ),
                      ),
                    ),
                    for (int i = 0; i < _dots; i++)
                      Positioned(
                        left: i * slot,
                        bottom: 6,
                        width: slot,
                        child: Center(
                          child: _suspectDot(
                            ringStrength:
                                (1 - (target - i).abs()).clamp(0.0, 1.0) *
                                    lock,
                            ringColor: context.skin.danger,
                            dotColor: context.skin.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.htpVisualWrongPick,
                style: context.skin.monoStyle(
                  size: 10,
                  letterSpacing: 1.8,
                  color: context.skin.paperFaint,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _suspectDot({
    required double ringStrength,
    required Color ringColor,
    required Color dotColor,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (ringStrength > 0)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor
                      .withValues(alpha: 0.9 * ringStrength),
                  width: 2,
                ),
              ),
            ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
