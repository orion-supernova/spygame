import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spygame/features/game/domain/role_assignment.dart';

void main() {
  group('assignRoles', () {
    test('assigns exactly `spyCount` spies', () {
      final rng = math.Random(1);
      for (var spies = 1; spies <= 3; spies++) {
        for (var n = spies + 1; n <= 8; n++) {
          final tokens = List.generate(n, (i) => 'tok-$i');
          final result = assignRoles(
            playerTokens: tokens,
            spyCount: spies,
            roles: const ['A', 'B', 'C', 'D', 'E'],
            rng: rng,
          );
          expect(result.length, n);
          final spyCount = result.where((a) => a.role == 'spy').length;
          expect(spyCount, spies, reason: 'spies=$spies n=$n');
        }
      }
    });

    test('every player gets exactly one role', () {
      final rng = math.Random(2);
      final tokens = List.generate(6, (i) => 't$i');
      final result = assignRoles(
        playerTokens: tokens,
        spyCount: 1,
        roles: const ['A', 'B', 'C', 'D', 'E'],
        rng: rng,
      );
      final unique = result.map((a) => a.clientToken).toSet();
      expect(unique.length, tokens.length);
    });

    test('non-spy roles come from the supplied list', () {
      final rng = math.Random(3);
      final tokens = List.generate(5, (i) => 't$i');
      const allowed = ['Alpha', 'Bravo', 'Charlie'];
      final result = assignRoles(
        playerTokens: tokens,
        spyCount: 1,
        roles: allowed,
        rng: rng,
      );
      for (final a in result.where((a) => a.role != 'spy')) {
        expect(allowed.contains(a.role), isTrue);
      }
    });

    test('handles spyCount >= players gracefully', () {
      final rng = math.Random(4);
      final tokens = ['a', 'b'];
      final result = assignRoles(
        playerTokens: tokens,
        spyCount: 5,
        roles: const ['X', 'Y'],
        rng: rng,
      );
      expect(result.length, 2);
      expect(result.every((a) => a.role == 'spy'), isTrue);
    });
  });
}
