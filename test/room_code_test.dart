import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spygame/core/utils/room_code.dart';

void main() {
  group('room code generator', () {
    test('produces 4 characters from the safe alphabet', () {
      final rng = math.Random(42);
      for (var i = 0; i < 1000; i++) {
        final code = generateRoomCode(rng);
        expect(code.length, 4);
        for (final ch in code.codeUnits) {
          expect(roomCodeAlphabet.codeUnits.contains(ch), isTrue);
        }
      }
    });

    test('excludes ambiguous glyphs (I, O, 0, 1, L)', () {
      const ambiguous = {'I', 'O', '0', '1', 'L'};
      for (final ch in roomCodeAlphabet.split('')) {
        expect(ambiguous.contains(ch), isFalse,
            reason: '$ch should not be in the alphabet');
      }
    });

    test('isValidRoomCode accepts valid codes and rejects invalid ones', () {
      expect(isValidRoomCode('ABCD'), isTrue);
      expect(isValidRoomCode('22XY'), isTrue);
      expect(isValidRoomCode('IO00'), isFalse); // ambiguous
      expect(isValidRoomCode('ABC'), isFalse); // too short
      expect(isValidRoomCode('ABCDE'), isFalse); // too long
      expect(isValidRoomCode('abcd'), isFalse); // lowercase
    });

    test('distribution roughly uniform across 10k samples', () {
      final rng = math.Random(7);
      final histogram = <String, int>{};
      for (final ch in roomCodeAlphabet.split('')) {
        histogram[ch] = 0;
      }
      const samples = 10000;
      for (var i = 0; i < samples; i++) { // ignore: prefer_const_declarations
        for (final ch in generateRoomCode(rng).split('')) {
          histogram[ch] = (histogram[ch] ?? 0) + 1;
        }
      }
      const expected = (samples * 4) / roomCodeAlphabet.length;
      for (final entry in histogram.entries) {
        expect(
          (entry.value - expected).abs() / expected,
          lessThan(0.25),
          reason: '${entry.key} skewed: ${entry.value} vs $expected',
        );
      }
    });
  });
}
