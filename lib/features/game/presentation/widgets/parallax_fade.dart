import 'package:flutter/material.dart';

/// Translates and fades a child based on a shared [ScrollController]'s offset.
/// The child "flies off" faster than the scroll for a depth effect, then
/// becomes invisible once [fadeRange] worth of scrolling has happened.
class ParallaxFade extends StatefulWidget {
  const ParallaxFade({
    super.key,
    required this.controller,
    required this.fadeRange,
    required this.child,
    this.translateFactor = 0.35,
  });

  final ScrollController controller;
  final double fadeRange;
  final double translateFactor;
  final Widget child;

  @override
  State<ParallaxFade> createState() => _ParallaxFadeState();
}

class _ParallaxFadeState extends State<ParallaxFade> {
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ParallaxFade old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final next = widget.controller.offset.clamp(0.0, widget.fadeRange * 1.5);
    if ((next - _offset).abs() < 0.5) return;
    setState(() => _offset = next);
  }

  @override
  Widget build(BuildContext context) {
    final opacity =
        (1 - (_offset / widget.fadeRange)).clamp(0.0, 1.0).toDouble();
    final dy = -_offset * widget.translateFactor;
    return IgnorePointer(
      ignoring: opacity < 0.05,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, dy),
          child: widget.child,
        ),
      ),
    );
  }
}
