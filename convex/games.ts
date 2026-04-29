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

type AnyCtx = QueryCtx | MutationCtx;

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
): Promise<Doc<'locations'>> {
  const all = await ctx.db.query('locations').collect();
  if (all.length === 0) {
    throw new ConvexError('No locations seeded — run locations:seed.');
  }
  const usedSet = new Set(used.map((id) => id.toString()));
  const remaining = all.filter((l) => !usedSet.has(l._id.toString()));
  const pool = remaining.length > 0 ? remaining : all;
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

  const location = await pickNextLocation(ctx, game.usedLocationIds);
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
    if (players.length < MIN_PLAYERS_TO_START) {
      throw new ConvexError(
        `Need at least ${MIN_PLAYERS_TO_START} players to start.`,
      );
    }
    if (!players.every((p) => p.isReady)) {
      throw new ConvexError('All players must tap Ready first.');
    }
    if (room.config.spyCount >= players.length) {
      throw new ConvexError('Spy count must be fewer than total players.');
    }

    const gameId = await ctx.db.insert('games', {
      roomId: room._id,
      status: 'active',
      currentRoundIndex: 0,
      totalRounds: room.config.roundCount,
      usedLocationIds: [],
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

  const nextIndex = round.index + 1;
  if (nextIndex > game.totalRounds) {
    await ctx.db.patch(game._id, {
      status: 'ended',
      currentRoundId: undefined,
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

  const endsAtMs = Date.now() + room.config.roundMinutes * 60_000;
  await startNewRound({
    ctx,
    gameId: game._id,
    index: nextIndex,
    endsAtMs,
  });
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

export const serverNow = query({
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
    return {
      role: assignment.role,
      location: location ? { _id: location._id, name: location.name } : null,
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
  args: { code: v.string() },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room || !room.currentGameId) {
      const locs = await ctx.db.query('locations').collect();
      return {
        locations: locs.map((l) => ({ _id: l._id, name: l.name })),
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

    const locs = await ctx.db.query('locations').collect();
    return {
      locations: locs.map((l) => ({ _id: l._id, name: l.name })),
      playedIds,
    };
  },
});
