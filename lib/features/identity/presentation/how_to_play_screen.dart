import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/grain_overlay.dart';
import '../../../core/utils/haptics.dart';

class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen>
    with TickerProviderStateMixin {
  static const _total = 5;

  final PageController _pages = PageController();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  )..forward();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    _reveal.dispose();
    _pulse.dispose();
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

    final cards = <_Card>[
      _Card(
        step: 'STEP 01 · OBJECTIVE',
        heading: 'A secret\nlocation.',
        body: 'Everyone shares one. Except for one of you.',
        visual: _DotGridVisual(pulse: _pulse),
      ),
      _Card(
        step: 'STEP 02 · MOST OF YOU',
        heading: 'You play\na role.',
        body:
            'A place. A role to play. Stay in character — vague answers smell like the spy.',
        visual: const _MockRoleCard(isSpy: false),
      ),
      _Card(
        step: 'STEP 03 · THE SPY',
        heading: "You don't\nknow where.",
        body:
            'One of you sees this card. Listen, ask cunning questions, figure out the location. Or bluff.',
        visual: const _MockRoleCard(isSpy: true),
      ),
      _Card(
        step: 'STEP 04 · THE ROUND',
        heading: 'Question\neach other.',
        body:
            'A few minutes per round. Specific enough to test the spy, vague enough not to hand them the location.',
        visual: const _TimerRingVisual(),
      ),
      _Card(
        step: 'STEP 05 · CALLING IT',
        heading: 'Argue\nit out.',
        body:
            "Time's up — debate together. No in-app vote, just talk. Spy wins by staying hidden. Everyone else wins by exposing them.",
        visual: const _CallItVisual(),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.ink)),
          const Positioned.fill(child: GrainOverlay()),
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
                        child: card.visual,
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
                        color: AppColors.paper,
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
                        color: AppColors.paperMuted,
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
              icon: const Icon(Icons.close_rounded, color: AppColors.paper),
              tooltip: 'Close',
            )
          else
            TextButton(
              onPressed: onSkip,
              child: Text(
                'SKIP',
                style: AppTypography.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: AppColors.paperMuted,
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
            color: active ? AppColors.lime : AppColors.inkOutline,
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
                    child: const Text('GOT IT'),
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
                            'NEXT',
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
                            size: 16,
                            color: AppColors.lime,
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
                'SWIPE',
                style: AppTypography.mono(
                  size: 11,
                  weight: FontWeight.w500,
                  letterSpacing: 2.2,
                  color: AppColors.paperFaint,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.paperFaint.withValues(alpha: 0.8),
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
        Container(width: 28, height: 2, color: AppColors.lime),
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

class _DotGridVisual extends StatelessWidget {
  const _DotGridVisual({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    const spyIndex = 4; // center cell of 3×3
    return SizedBox(
      width: 200,
      height: 200,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 28,
          crossAxisSpacing: 28,
        ),
        itemCount: 9,
        itemBuilder: (_, i) {
          final isSpy = i == spyIndex;
          if (!isSpy) {
            return Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return AnimatedBuilder(
            animation: pulse,
            builder: (_, _) {
              final t = pulse.value;
              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 18 + 18 * t,
                      height: 18 + 18 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.signalRed
                            .withValues(alpha: 0.18 * (1 - t)),
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.signalRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MockRoleCard extends StatelessWidget {
  const _MockRoleCard({required this.isSpy});
  final bool isSpy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isSpy ? AppColors.signalRed : AppColors.lime;
    return Container(
      width: 280,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSpy
            ? AppColors.signalRed.withValues(alpha: 0.12)
            : AppColors.inkRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isSpy ? 'COVER ROLE' : 'YOU ARE',
                style: AppTypography.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: accent,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isSpy) ...[
            Text(
              'THE SPY',
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.signalRed,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Location: unknown.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.paper,
              ),
            ),
          ] else ...[
            Text(
              'Bartender',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.paper,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AT',
              style: AppTypography.mono(
                size: 11,
                weight: FontWeight.w600,
                letterSpacing: 2.2,
                color: AppColors.paperFaint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tiki Bar',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.lime,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimerRingVisual extends StatelessWidget {
  const _TimerRingVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: 3,
              color: AppColors.lime,
              backgroundColor: AppColors.inkOutline,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '5:00',
                style: AppTypography.mono(
                  size: 40,
                  weight: FontWeight.w700,
                  letterSpacing: -1,
                  color: AppColors.paper,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PER ROUND',
                style: AppTypography.mono(
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: AppColors.paperFaint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CallItVisual extends StatelessWidget {
  const _CallItVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.inkOutline),
      ),
      child: Column(
        children: [
          Text(
            'NO VOTE',
            style: AppTypography.mono(
              size: 22,
              weight: FontWeight.w700,
              letterSpacing: 4,
              color: AppColors.paper,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 2,
            color: AppColors.lime,
          ),
          const SizedBox(height: 12),
          Text(
            'JUST TALK',
            style: AppTypography.mono(
              size: 22,
              weight: FontWeight.w700,
              letterSpacing: 4,
              color: AppColors.lime,
            ),
          ),
        ],
      ),
    );
  }
}
