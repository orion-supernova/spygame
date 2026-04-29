/**
 * Spy + role assignment.
 *
 * - Picks `spyCount` random tokens to be the spy(ies).
 * - Each non-spy gets a unique role from the location's role list. If there
 *   are more players than roles, roles repeat (random shuffle, then cycle).
 */
export function shuffle<T>(arr: T[]): T[] {
  const copy = [...arr];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

export function assignRoles(args: {
  playerTokens: string[];
  spyCount: number;
  roles: string[];
}): Array<{ clientToken: string; role: string }> {
  const { playerTokens, spyCount, roles } = args;
  const shuffled = shuffle(playerTokens);
  const spies = shuffled.slice(0, Math.min(spyCount, shuffled.length));
  const civilians = shuffled.slice(spies.length);

  const civilianRoles = shuffle(roles);
  const out: Array<{ clientToken: string; role: string }> = spies.map((t) => ({
    clientToken: t,
    role: 'spy',
  }));
  for (let i = 0; i < civilians.length; i++) {
    out.push({
      clientToken: civilians[i],
      role: civilianRoles[i % civilianRoles.length],
    });
  }
  return out;
}
