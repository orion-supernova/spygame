import 'dart:math' as math;

/// Mirror of the Convex-side 4-char generator. Used by tests and for any
/// client-side validation. Keep in sync with `convex/helpers/code.ts`.
const String roomCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

String generateRoomCode([math.Random? rng]) {
  final r = rng ?? math.Random();
  final buf = StringBuffer();
  for (var i = 0; i < 4; i++) {
    buf.write(roomCodeAlphabet[r.nextInt(roomCodeAlphabet.length)]);
  }
  return buf.toString();
}

bool isValidRoomCode(String input) {
  if (input.length != 4) return false;
  for (final ch in input.codeUnits) {
    if (!roomCodeAlphabet.codeUnits.contains(ch)) return false;
  }
  return true;
}
