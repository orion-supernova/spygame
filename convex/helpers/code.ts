/**
 * 4-character room codes. Alphabet excludes ambiguous glyphs (I/O/0/1/L)
 * to make verbal sharing painless. 32^4 = ~1M codes — plenty for casual
 * use. Convex's unique index on rooms.code provides hard enforcement; the
 * generator + retry loop just makes collisions cheap.
 */
export const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

export function generateRoomCode(): string {
  let code = '';
  for (let i = 0; i < 4; i++) {
    const idx = Math.floor(Math.random() * CODE_ALPHABET.length);
    code += CODE_ALPHABET[idx];
  }
  return code;
}

export function normalizeCode(input: string): string {
  return input.trim().toUpperCase();
}

export function isValidCode(input: string): boolean {
  if (input.length !== 4) return false;
  for (const ch of input) {
    if (!CODE_ALPHABET.includes(ch)) return false;
  }
  return true;
}
