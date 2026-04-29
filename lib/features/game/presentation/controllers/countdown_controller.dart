import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/convex/server_time_provider.dart';

/// Time-derived state for the countdown ring. The deadline (`endsAtServerMs`)
/// is set once per round; we subtract the synced server-now from it on every
/// tick to compute remaining. Locking the screen, backgrounding the app,
/// changing the system clock — none of these affect the deadline. Resume
/// snaps back to the correct value because we re-derive from absolute time.
class CountdownState {
  const CountdownState({
    required this.endsAtServerMs,
    required this.totalMs,
    required this.remainingMs,
  });

  final int endsAtServerMs;
  final int totalMs;
  final int remainingMs;

  bool get expired => remainingMs <= 0;
  double get progress {
    if (totalMs <= 0) return 0;
    return (remainingMs / totalMs).clamp(0.0, 1.0);
  }

  int get seconds =>
      (remainingMs / 1000).ceil().clamp(0, (totalMs / 1000).ceil());
}

class CountdownArgs {
  const CountdownArgs({required this.endsAtServerMs, required this.totalMs});
  final int endsAtServerMs;
  final int totalMs;

  @override
  bool operator ==(Object other) =>
      other is CountdownArgs &&
      other.endsAtServerMs == endsAtServerMs &&
      other.totalMs == totalMs;
  @override
  int get hashCode => Object.hash(endsAtServerMs, totalMs);
}

class CountdownController
    extends AutoDisposeFamilyNotifier<CountdownState, CountdownArgs> {
  Ticker? _ticker;

  @override
  CountdownState build(CountdownArgs args) {
    _ticker = Ticker((_) => _emit())..start();
    ref.onDispose(() {
      _ticker?.dispose();
      _ticker = null;
    });
    return _compute(args);
  }

  CountdownState _compute(CountdownArgs args) {
    final offset = ref.read(serverTimeOffsetProvider);
    final nowServer = DateTime.now().millisecondsSinceEpoch + offset;
    final remaining = args.endsAtServerMs - nowServer;
    return CountdownState(
      endsAtServerMs: args.endsAtServerMs,
      totalMs: args.totalMs,
      remainingMs: remaining,
    );
  }

  void _emit() {
    state = _compute(arg);
  }
}

final countdownControllerProvider = NotifierProvider.autoDispose
    .family<CountdownController, CountdownState, CountdownArgs>(
      CountdownController.new,
    );
