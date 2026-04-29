import 'dart:math' as math;

/// Pure-Dart mirror of `convex/helpers/assign.ts` so we can unit-test the
/// invariants of role assignment without spinning up Convex.
List<RoleAssignment> assignRoles({
  required List<String> playerTokens,
  required int spyCount,
  required List<String> roles,
  math.Random? rng,
}) {
  final r = rng ?? math.Random();
  final shuffled = [...playerTokens]..shuffle(r);
  final spies = shuffled.take(math.min(spyCount, shuffled.length)).toList();
  final civilians = shuffled.skip(spies.length).toList();
  final shuffledRoles = [...roles]..shuffle(r);

  final out = <RoleAssignment>[
    for (final t in spies) RoleAssignment(t, 'spy'),
  ];
  for (var i = 0; i < civilians.length; i++) {
    out.add(RoleAssignment(
      civilians[i],
      shuffledRoles[i % shuffledRoles.length],
    ));
  }
  return out;
}

class RoleAssignment {
  const RoleAssignment(this.clientToken, this.role);
  final String clientToken;
  final String role;
}
