import 'package:flutter_test/flutter_test.dart';

/// Pure-function mirror of CountdownController._compute, used so the
/// background-resilient countdown logic can be tested without a Ticker.
({int remainingMs, double progress, int seconds}) deriveCountdown({
  required int endsAtServerMs,
  required int totalMs,
  required int serverNowMs,
}) {
  final remaining = endsAtServerMs - serverNowMs;
  final progress = totalMs <= 0
      ? 0.0
      : (remaining / totalMs).clamp(0.0, 1.0);
  final seconds = (remaining / 1000).ceil().clamp(0, 99 * 60);
  return (remainingMs: remaining, progress: progress, seconds: seconds);
}

void main() {
  group('countdown derivation', () {
    test('halfway through a 7-minute round', () {
      const total = 7 * 60 * 1000;
      const ends = 7_000_000;
      final r = deriveCountdown(
        endsAtServerMs: ends,
        totalMs: total,
        serverNowMs: ends - total ~/ 2,
      );
      expect(r.remainingMs, total ~/ 2);
      expect(r.progress, closeTo(0.5, 1e-9));
      expect(r.seconds, total ~/ 2 ~/ 1000);
    });

    test('clamps to zero after expiry', () {
      const total = 60_000;
      final r = deriveCountdown(
        endsAtServerMs: 1000,
        totalMs: total,
        serverNowMs: 5000,
      );
      expect(r.remainingMs, lessThan(0));
      expect(r.progress, 0.0);
      expect(r.seconds, 0);
    });

    test('ceil semantics so 0.4s shows 1s, not 0', () {
      final r = deriveCountdown(
        endsAtServerMs: 400,
        totalMs: 60_000,
        serverNowMs: 0,
      );
      expect(r.seconds, 1);
    });

    test('works with backgrounded resume scenario', () {
      // Simulate phone backgrounded for 30s during a 5-min round.
      const total = 5 * 60 * 1000;
      const start = 0;
      const ends = start + total;
      const offset = 30_000; // 30s passed while away

      final beforeBg = deriveCountdown(
        endsAtServerMs: ends,
        totalMs: total,
        serverNowMs: start,
      );
      final afterResume = deriveCountdown(
        endsAtServerMs: ends,
        totalMs: total,
        serverNowMs: start + offset,
      );
      expect(beforeBg.remainingMs - afterResume.remainingMs, offset);
    });

    test('progress is 1.0 at start, 0.0 at end', () {
      const total = 60_000;
      const ends = 100_000;
      expect(
        deriveCountdown(
          endsAtServerMs: ends,
          totalMs: total,
          serverNowMs: ends - total,
        ).progress,
        1.0,
      );
      expect(
        deriveCountdown(
          endsAtServerMs: ends,
          totalMs: total,
          serverNowMs: ends,
        ).progress,
        0.0,
      );
    });
  });
}
