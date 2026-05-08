import { ConvexError, v } from 'convex/values';

import { internal } from './_generated/api';
import { Doc, Id } from './_generated/dataModel';
import {
  MutationCtx,
  QueryCtx,
  internalMutation,
  mutation,
  query,
} from './_generated/server';
import { assignRoles } from './helpers/assign';
import { normalizeCode } from './helpers/code';

const MIN_PLAYERS_TO_START = 3;

// Solo-test escape hatch. Set `TESTING_MODE=true` on the dev Convex
// deployment to allow 1-player games (and a spy count equal to the player
// count). Leave unset in prod. Convex exposes env vars via `process.env`
// at runtime — types come from `@types/node`, listed in
// `convex/tsconfig.json` so the node-runtime push action also typechecks.
const TESTING_MODE = process.env.TESTING_MODE === 'true';

type AnyCtx = QueryCtx | MutationCtx;

// Locale projection — the only locales the server ever talks. Optional on
// public queries so legacy clients without the arg keep working (English).
const LOCALE_VALIDATOR = v.optional(v.union(v.literal('en'), v.literal('tr')));
type Locale = 'en' | 'tr';

function localizeLocation(
  loc: Doc<'locations'>,
  locale: Locale | undefined,
): { name: string; roles: string[] } {
  if (locale === 'tr' && loc.translations?.tr) {
    return loc.translations.tr;
  }
  return { name: loc.name, roles: loc.roles };
}

// English role string is the stable key we store in `roundAssignments`.
// Find it by index in `loc.roles`, then read the same index from the
// localized roles array. Falls back to English for any mismatch.
function localizeRole(
  loc: Doc<'locations'>,
  englishRole: string,
  locale: Locale | undefined,
): string {
  if (locale !== 'tr' || !loc.translations?.tr) return englishRole;
  const idx = loc.roles.indexOf(englishRole);
  if (idx < 0) return englishRole;
  return loc.translations.tr.roles[idx] ?? englishRole;
}

async function findRoomByCode(
  ctx: AnyCtx,
  code: string,
): Promise<Doc<'rooms'> | null> {
  return ctx.db
    .query('rooms')
    .withIndex('by_code', (q) => q.eq('code', code))
    .first();
}

async function pickNextLocation(
  ctx: MutationCtx,
  used: Id<'locations'>[],
  ownedBundleSlugs: Set<string>,
  disabledLocationIds: Set<string>,
): Promise<Doc<'locations'>> {
  const all = await ctx.db.query('locations').collect();
  // Filter to free locations + owned bundles, then drop the host's
  // per-game blacklist. Server doesn't validate ownership claims (no
  // accounts) — RevenueCat-backed validation is a future task.
  const eligible = all.filter(
    (l) =>
      (l.bundleSlug == null || ownedBundleSlugs.has(l.bundleSlug)) &&
      !disabledLocationIds.has(l._id.toString()),
  );
  if (eligible.length === 0) {
    throw new ConvexError(
      'No locations available — host disabled all of them.',
    );
  }
  const usedSet = new Set(used.map((id) => id.toString()));
  const remaining = eligible.filter((l) => !usedSet.has(l._id.toString()));
  const pool = remaining.length > 0 ? remaining : eligible;
  return pool[Math.floor(Math.random() * pool.length)];
}

async function startNewRound(args: {
  ctx: MutationCtx;
  gameId: Id<'games'>;
  index: number;
  endsAtMs: number;
}): Promise<Id<'rounds'>> {
  const { ctx, gameId, index, endsAtMs } = args;
  const game = await ctx.db.get(gameId);
  if (!game) throw new ConvexError('Game vanished.');
  const room = await ctx.db.get(game.roomId);
  if (!room) throw new ConvexError('Room vanished.');

  const ownedBundleSlugs = new Set(game.ownedBundleSlugs ?? []);
  const disabledLocationIds = new Set(
    (game.disabledLocationIds ?? []).map((id) => id.toString()),
  );
  const location = await pickNextLocation(
    ctx,
    game.usedLocationIds,
    ownedBundleSlugs,
    disabledLocationIds,
  );
  const roundId = await ctx.db.insert('rounds', {
    gameId,
    index,
    startedAtMs: Date.now(),
    endsAtMs,
    status: 'active',
  });
  await ctx.db.insert('roundSecrets', {
    roundId,
    locationId: location._id,
  });

  const players = await ctx.db
    .query('players')
    .withIndex('by_room', (q) => q.eq('roomId', game.roomId))
    .collect();

  const assignments = assignRoles({
    playerTokens: players.map((p) => p.clientToken),
    spyCount: room.config.spyCount,
    roles: location.roles,
  });
  for (const a of assignments) {
    await ctx.db.insert('roundAssignments', {
      roundId,
      clientToken: a.clientToken,
      role: a.role,
    });
  }

  await ctx.db.patch(gameId, {
    currentRoundId: roundId,
    currentRoundIndex: index,
    usedLocationIds: [...game.usedLocationIds, location._id],
  });

  await ctx.scheduler.runAfter(
    Math.max(0, endsAtMs - Date.now()),
    internal.games.endRoundInternal,
    { roundId, expectedEndsAtMs: endsAtMs, reason: 'timer' as const },
  );

  return roundId;
}

export const startGame = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
    // Bundle slugs the host claims to own. Server does not validate the
    // claim because there are no accounts; trust the client. Free
    // locations are always included regardless of this list.
    ownedBundleSlugs: v.optional(v.array(v.string())),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) throw new ConvexError('Room not found.');
    if (room.ownerToken !== args.clientToken) {
      throw new ConvexError('Only the host can start the game.');
    }
    if (room.status !== 'lobby') {
      throw new ConvexError('Game already started.');
    }
    const players = await ctx.db
      .query('players')
      .withIndex('by_room', (q) => q.eq('roomId', room._id))
      .collect();
    if (!TESTING_MODE && players.length < MIN_PLAYERS_TO_START) {
      throw new ConvexError(
        `Need at least ${MIN_PLAYERS_TO_START} players to start.`,
      );
    }
    if (!players.every((p) => p.isReady)) {
      throw new ConvexError('All players must tap Ready first.');
    }
    const spyOverflow = TESTING_MODE
      ? room.config.spyCount > players.length
      : room.config.spyCount >= players.length;
    if (spyOverflow) {
      throw new ConvexError('Spy count must be fewer than total players.');
    }

    const gameId = await ctx.db.insert('games', {
      roomId: room._id,
      status: 'active',
      phase: 'playing',
      currentRoundIndex: 0,
      totalRounds: room.config.roundCount,
      usedLocationIds: [],
      ownedBundleSlugs: args.ownedBundleSlugs ?? [],
      disabledLocationIds: room.disabledLocationIds ?? [],
    });
    await ctx.db.patch(room._id, {
      status: 'inGame',
      currentGameId: gameId,
    });

    const endsAtMs = Date.now() + room.config.roundMinutes * 60_000;
    await startNewRound({ ctx, gameId, index: 1, endsAtMs });
    return { gameId };
  },
});

export const endRoundManual = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room || !room.currentGameId) return;
    if (room.ownerToken !== args.clientToken) {
      throw new ConvexError('Only the host can end a round early.');
    }
    const game = await ctx.db.get(room.currentGameId);
    if (!game || !game.currentRoundId) return;
    await endRoundCore(ctx, {
      roundId: game.currentRoundId,
      expectedEndsAtMs: null,
      reason: 'manual',
    });
  },
});

/**
 * Idempotent. Any client may call this on app resume if the local clock
 * thinks the round should have ended. Server confirms before acting.
 */
export const endRoundIfDue = mutation({
  args: {
    roundId: v.id('rounds'),
    expectedEndsAtMs: v.number(),
  },
  handler: async (ctx, args) => {
    const round = await ctx.db.get(args.roundId);
    if (!round) return;
    if (round.status === 'ended') return;
    if (round.endsAtMs !== args.expectedEndsAtMs) return;
    if (Date.now() < round.endsAtMs) return;
    await endRoundCore(ctx, {
      roundId: args.roundId,
      expectedEndsAtMs: args.expectedEndsAtMs,
      reason: 'timer',
    });
  },
});

/**
 * Core round-end logic. Used by the public `endRoundManual`/`endRoundIfDue`
 * mutations and by the scheduled `endRoundInternal` so all paths converge.
 * Mutation handlers can't `runMutation` each other directly in Convex, so
 * we share a plain async helper instead.
 */
async function endRoundCore(
  ctx: MutationCtx,
  args: {
    roundId: Id<'rounds'>;
    expectedEndsAtMs: number | null;
    reason: 'timer' | 'manual';
  },
): Promise<void> {
  const round = await ctx.db.get(args.roundId);
  if (!round) return;
  if (round.status === 'ended') return;
  if (
    args.expectedEndsAtMs !== null &&
    round.endsAtMs !== args.expectedEndsAtMs
  ) {
    return;
  }
  await ctx.db.patch(args.roundId, {
    status: 'ended',
    endedReason: args.reason,
  });

  const game = await ctx.db.get(round.gameId);
  if (!game) return;
  const room = await ctx.db.get(game.roomId);
  if (!room) return;

  // Identify the spy for this round so the client can render a reveal modal
  // during intermission (and on the final round, before the game-summary
  // navigation). The token is no longer secret once the round has ended.
  const assignmentsForRound = await ctx.db
    .query('roundAssignments')
    .withIndex('by_round_and_token', (q) => q.eq('roundId', args.roundId))
    .collect();
  const spyAssignment = assignmentsForRound.find((a) => a.role === 'spy');
  const spyPatch: {
    lastSpyRevealRoundIndex?: number;
    lastSpyClientToken?: string;
  } = spyAssignment
    ? {
        lastSpyRevealRoundIndex: round.index,
        lastSpyClientToken: spyAssignment.clientToken,
      }
    : {};

  // Snapshot push-notification targets BEFORE we mutate room state so the
  // dispatcher gets a stable view, even if a leaveRoom races in. Passing
  // the materialized list (rather than just roundId) also lets the action
  // skip a re-walk of room → players. Tokens may still be invalid by the
  // time the push lands; the action handles 410/UNREGISTERED cleanup.
  const allPlayersForPush = await ctx.db
    .query('players')
    .withIndex('by_room', (q) => q.eq('roomId', game.roomId))
    .collect();
  const pushTargets = allPlayersForPush
    .filter((p) => p.pushTokenApnsLiveActivity || p.pushTokenFcm)
    .map((p) => ({
      playerId: p._id,
      apnsLiveActivityToken: p.pushTokenApnsLiveActivity,
      apnsGateway: p.pushTokenApnsGateway,
      fcmToken: p.pushTokenFcm,
      locale: (p.locale ?? 'en') as 'en' | 'tr',
    }));

  const nextIndex = round.index + 1;
  const gameEnded = nextIndex > game.totalRounds;

  if (pushTargets.length > 0) {
    await ctx.scheduler.runAfter(
      0,
      internal.notifications.dispatchRoundEndedPush,
      {
        targets: pushTargets,
        roundId: args.roundId,
        roundIndex: round.index,
        endedReason: args.reason,
        gameEnded,
      },
    );
  }

  if (gameEnded) {
    await ctx.db.patch(game._id, {
      status: 'ended',
      phase: 'ended',
      currentRoundId: undefined,
      ...spyPatch,
    });
    await ctx.db.patch(room._id, { status: 'ended' });
    // Cascade-delete the room and all its data after a 30-min grace
    // period. The hourly `purgeStale` cron is the safety net if this
    // somehow doesn't fire.
    await ctx.scheduler.runAfter(
      30 * 60 * 1000,
      internal.maintenance.purgeRoom,
      { roomId: room._id },
    );
    return;
  }

  // Enter intermission: everyone needs to debrief and tap Ready before the
  // next round starts. setReady (in rooms.ts) detects all-ready and
  // transitions the game into 'starting' with a 3-second countdown.
  await ctx.db.patch(game._id, {
    phase: 'between',
    nextRoundStartsAtMs: undefined,
    ...spyPatch,
  });
  for (const p of allPlayersForPush) {
    if (p.isReady) {
      await ctx.db.patch(p._id, { isReady: false });
    }
  }
}

/**
 * Called by the scheduler 3 seconds after `triggerIntermissionCountdown`
 * flips the game into `phase='starting'`. Verifies the game is still in
 * the expected state, then actually creates the next round.
 */
export const startNextQueuedRound = internalMutation({
  args: {
    gameId: v.id('games'),
    expectedStartAtMs: v.number(),
  },
  handler: async (ctx, args) => {
    const game = await ctx.db.get(args.gameId);
    if (!game) return;
    if (game.phase !== 'starting') return;
    if (game.nextRoundStartsAtMs !== args.expectedStartAtMs) return;
    const room = await ctx.db.get(game.roomId);
    if (!room) return;

    const endsAtMs = Date.now() + room.config.roundMinutes * 60_000;
    await startNewRound({
      ctx,
      gameId: game._id,
      index: game.currentRoundIndex + 1,
      endsAtMs,
    });
    // startNewRound patches currentRoundId/currentRoundIndex; flip phase
    // back to 'playing' and clear the countdown stamp.
    await ctx.db.patch(game._id, {
      phase: 'playing',
      nextRoundStartsAtMs: undefined,
    });
  },
});

/**
 * Called from `setReady` in rooms.ts when the last unreadied player flips
 * their ready bit during the 'between' phase. Sets the 3-second countdown
 * and schedules `startNextQueuedRound` to fire when it expires.
 *
 * Exported as a regular helper (not a mutation) so it can run inside the
 * setReady mutation's transaction.
 */
export async function triggerIntermissionCountdown(
  ctx: MutationCtx,
  gameId: Id<'games'>,
): Promise<void> {
  const game = await ctx.db.get(gameId);
  if (!game) return;
  if (game.phase !== 'between') return;
  const startsAtMs = Date.now() + 3_000;
  await ctx.db.patch(gameId, {
    phase: 'starting',
    nextRoundStartsAtMs: startsAtMs,
  });
  await ctx.scheduler.runAfter(
    3_000,
    internal.games.startNextQueuedRound,
    { gameId, expectedStartAtMs: startsAtMs },
  );
}

export const endRoundInternal = internalMutation({
  args: {
    roundId: v.id('rounds'),
    expectedEndsAtMs: v.union(v.number(), v.null()),
    reason: v.union(v.literal('timer'), v.literal('manual')),
  },
  handler: async (ctx, args) => {
    await endRoundCore(ctx, {
      roundId: args.roundId,
      expectedEndsAtMs: args.expectedEndsAtMs,
      reason: args.reason,
    });
  },
});

// Must be a mutation (not a query) — Convex caches query results by
// (name, args), so a no-arg `() => Date.now()` query freezes at first
// call and never refreshes. Mutations always execute fresh.
export const serverNow = mutation({
  args: {},
  handler: async () => Date.now(),
});

/**
 * Per-caller secret query. Returns the role assignment for THIS client's
 * token only. Other players cannot subscribe to this and learn each
 * other's role even if they know a roundId.
 */
export const getMyRole = query({
  args: {
    roundId: v.id('rounds'),
    clientToken: v.string(),
    locale: LOCALE_VALIDATOR,
  },
  handler: async (ctx, args) => {
    const round = await ctx.db.get(args.roundId);
    if (!round) return null;
    const assignment = await ctx.db
      .query('roundAssignments')
      .withIndex('by_round_and_token', (q) =>
        q.eq('roundId', args.roundId).eq('clientToken', args.clientToken),
      )
      .first();
    if (!assignment) return null;

    if (assignment.role === 'spy') {
      return {
        role: 'spy' as const,
        location: null,
        roundIndex: round.index,
      };
    }
    const secret = await ctx.db
      .query('roundSecrets')
      .withIndex('by_round', (q) => q.eq('roundId', args.roundId))
      .first();
    if (!secret) return null;
    const location = await ctx.db.get(secret.locationId);
    if (!location) {
      return {
        role: assignment.role,
        location: null,
        roundIndex: round.index,
      };
    }
    const localizedName = localizeLocation(location, args.locale).name;
    const localizedRole = localizeRole(location, assignment.role, args.locale);
    return {
      role: localizedRole,
      location: { _id: location._id, name: localizedName },
      roundIndex: round.index,
    };
  },
});

/**
 * Returns the full location list with `playedIds` set. The played list
 * reveals only ENDED rounds — never the currently-active one (that would
 * trivially expose the current location to the spy).
 */
export const watchLocations = query({
  args: {
    code: v.string(),
    locale: LOCALE_VALIDATOR,
    // Used pre-game (no active game yet) to scope the preview pool to
    // free + owned bundles. During an active game the snapshot stored on
    // `game.ownedBundleSlugs` takes precedence so all clients see the
    // same grid regardless of their own ownership state.
    ownedBundleSlugs: v.optional(v.array(v.string())),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    const all = await ctx.db.query('locations').collect();

    if (!room || !room.currentGameId) {
      const owned = new Set(args.ownedBundleSlugs ?? []);
      const disabled = new Set(
        (room?.disabledLocationIds ?? []).map((id) => id.toString()),
      );
      const eligible = all.filter(
        (l) =>
          (l.bundleSlug == null || owned.has(l.bundleSlug)) &&
          !disabled.has(l._id.toString()),
      );
      return {
        locations: eligible.map((l) => ({
          _id: l._id,
          name: localizeLocation(l, args.locale).name,
        })),
        playedIds: [] as Id<'locations'>[],
      };
    }
    const game = await ctx.db.get(room.currentGameId);
    if (!game) {
      return {
        locations: [] as { _id: Id<'locations'>; name: string }[],
        playedIds: [] as Id<'locations'>[],
      };
    }

    const allRounds = await ctx.db
      .query('rounds')
      .withIndex('by_game', (q) => q.eq('gameId', game._id))
      .collect();
    const endedRoundIds = allRounds
      .filter((r) => r.status === 'ended')
      .map((r) => r._id);
    const playedIds: Id<'locations'>[] = [];
    for (const rid of endedRoundIds) {
      const secret = await ctx.db
        .query('roundSecrets')
        .withIndex('by_round', (q) => q.eq('roundId', rid))
        .first();
      if (secret) playedIds.push(secret.locationId);
    }

    const gameOwned = new Set(game.ownedBundleSlugs ?? []);
    const gameDisabled = new Set(
      (game.disabledLocationIds ?? []).map((id) => id.toString()),
    );
    const eligible = all.filter(
      (l) =>
        (l.bundleSlug == null || gameOwned.has(l.bundleSlug)) &&
        !gameDisabled.has(l._id.toString()),
    );
    return {
      locations: eligible.map((l) => ({
        _id: l._id,
        name: localizeLocation(l, args.locale).name,
      })),
      playedIds,
    };
  },
});
