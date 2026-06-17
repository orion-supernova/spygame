import 'package:flutter/material.dart';

import '../../../core/theme/skin_context.dart';
import '../domain/role.dart';

const _kLocationGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  childAspectRatio: 3.4,
);

class LocationGrid extends StatelessWidget {
  const LocationGrid({super.key, required this.board});
  final LocationsBoard board;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: board.locations.length,
      gridDelegate: _kLocationGridDelegate,
      itemBuilder: (context, i) {
        final loc = board.locations[i];
        final played = board.isPlayed(loc.id);
        return _LocationCell(name: loc.name, played: played);
      },
    );
  }
}

class SliverLocationGrid extends StatelessWidget {
  const SliverLocationGrid({super.key, required this.board});
  final LocationsBoard board;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: _kLocationGridDelegate,
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final loc = board.locations[i];
          final played = board.isPlayed(loc.id);
          return _LocationCell(name: loc.name, played: played);
        },
        childCount: board.locations.length,
      ),
    );
  }
}

class _LocationCell extends StatelessWidget {
  const _LocationCell({required this.name, required this.played});
  final String name;
  final bool played;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final reduceMotion = MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: played ? 1 : 0, end: played ? 1 : 0),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: skin.inkRaised,
            borderRadius: BorderRadius.circular(skin.cardRadius.clamp(2, 14)),
            border: Border.all(
              color: skin.inkOutline,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: skin.monoStyle(
                  size: 13,
                  weight: FontWeight.w500,
                  letterSpacing: 0.4,
                  color: played
                      ? skin.paperFaint
                      : skin.paper,
                ),
              ),
              // Strikethrough that draws in.
              Positioned(
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  widthFactor: t,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 1.6,
                    color: skin.danger.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
