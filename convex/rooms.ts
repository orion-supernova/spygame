import { ConvexError, v } from 'convex/values';

import { Doc, Id } from './_generated/dataModel';
import {
  MutationCtx,
  QueryCtx,
  mutation,
  query,
} from './_generated/server';
import { triggerIntermissionCountdown } from './games';
import { generateRoomCode, isValidCode, normalizeCode } from './helpers/code';

const MAX_PLAYERS = 12;

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

async function getPlayers(
  ctx: AnyCtx,
  roomId: Id<'rooms'>,
): Promise<Doc<'players'>[]> {
  return ctx.db
    .query('players')
    .withIndex('by_room', (q) => q.eq('roomId', roomId))
    .collect();
}

function publicConfig(room: Doc<'rooms'>) {
  return {
    spyCount: room.config.spyCount,
    roundMinutes: room.config.roundMinutes,
    roundCount: room.config.roundCount,
  };
}

export const createRoom = mutation({
  args: {
    displayName: v.string(),
    clientToken: v.string(),
  },
  handler: async (ctx, args) => {
    const name = args.displayName.trim();
    if (name.length < 1 || name.length > 24) {
      throw new ConvexError('Display name must be 1–24 characters.');
    }

    let code = '';
    let inserted = false;
    let roomId: Id<'rooms'> | null = null;
    for (let attempt = 0; attempt < 6; attempt++) {
      code = generateRoomCode();
      const existing = await findRoomByCode(ctx, code);
      if (existing) continue;
      roomId = await ctx.db.insert('rooms', {
        code,
        ownerToken: args.clientToken,
        status: 'lobby',
        config: { spyCount: 1, roundMinutes: 7, roundCount: 5 },
        createdAt: Date.now(),
      });
      inserted = true;
      break;
    }
    if (!inserted || !roomId) {
      throw new ConvexError('Could not generate a unique code. Try again.');
    }

    await ctx.db.insert('players', {
      roomId,
      clientToken: args.clientToken,
      displayName: name,
      isReady: false,
      joinedAt: Date.now(),
      lastSeenAt: Date.now(),
    });

    return { code };
  },
});

export const joinRoom = mutation({
  args: {
    code: v.string(),
    displayName: v.string(),
    clientToken: v.string(),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    if (!isValidCode(code)) {
      throw new ConvexError('Invalid room code.');
    }
    const name = args.displayName.trim();
    if (name.length < 1 || name.length > 24) {
      throw new ConvexError('Display name must be 1–24 characters.');
    }

    const room = await findRoomByCode(ctx, code);
    if (!room) throw new ConvexError('No room with that code.');
    if (room.status !== 'lobby') {
      throw new ConvexError('That game has already started.');
    }

    const players = await getPlayers(ctx, room._id);
    const existing = players.find((p) => p.clientToken === args.clientToken);
    if (existing) {
      // Idempotent rejoin (e.g. closed app and reopened) — refresh metadata.
      await ctx.db.patch(existing._id, {
        displayName: name,
        lastSeenAt: Date.now(),
      });
      return { code };
    }
    if (players.length >= MAX_PLAYERS) {
      throw new ConvexError('That room is full.');
    }

    await ctx.db.insert('players', {
      roomId: room._id,
      clientToken: args.clientToken,
      displayName: name,
      isReady: false,
      joinedAt: Date.now(),
      lastSeenAt: Date.now(),
    });
    return { code };
  },
});

export const leaveRoom = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) return;

    const players = await getPlayers(ctx, room._id);
    const me = players.find((p) => p.clientToken === args.clientToken);
    if (me) await ctx.db.delete(me._id);

    const remaining = players.filter((p) => p.clientToken !== args.clientToken);

    if (remaining.length === 0) {
      // Last person out — clean the room.
      await ctx.db.delete(room._id);
      return;
    }

    if (room.ownerToken === args.clientToken && room.status === 'lobby') {
      // Transfer ownership to the player who joined earliest.
      const next = [...remaining].sort((a, b) => a.joinedAt - b.joinedAt)[0];
      await ctx.db.patch(room._id, { ownerToken: next.clientToken });
    }
  },
});

export const setReady = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
    ready: v.boolean(),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) throw new ConvexError('Room not found.');

    // Ready toggling is allowed in the lobby AND during between-rounds
    // intermission. It's a no-op while a round is in flight (no UI for it
    // anyway) and after the game has ended.
    let inIntermission = false;
    if (room.status === 'lobby') {
      // ok
    } else if (room.status === 'inGame' && room.currentGameId) {
      const game = await ctx.db.get(room.currentGameId);
      if (game?.phase !== 'between') return;
      inIntermission = true;
    } else {
      return;
    }

    const player = await ctx.db
      .query('players')
      .withIndex('by_room_and_token', (q) =>
        q.eq('roomId', room._id).eq('clientToken', args.clientToken),
      )
      .first();
    if (!player) throw new ConvexError('You are not in this room.');
    await ctx.db.patch(player._id, {
      isReady: args.ready,
      lastSeenAt: Date.now(),
    });

    // If we just flipped to ready during a between-rounds intermission AND
    // every player is now ready, kick off the 3-second start countdown.
    if (args.ready && inIntermission && room.currentGameId) {
      const players = await getPlayers(ctx, room._id);
      const allReady = players.every((p) => p.isReady);
      if (allReady) {
        await triggerIntermissionCountdown(ctx, room.currentGameId);
      }
    }
  },
});

export const updateConfig = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
    spyCount: v.number(),
    roundMinutes: v.number(),
    roundCount: v.number(),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) throw new ConvexError('Room not found.');
    if (room.ownerToken !== args.clientToken) {
      throw new ConvexError('Only the host can change the settings.');
    }
    if (room.status !== 'lobby') {
      throw new ConvexError('Cannot change settings during a game.');
    }
    if (args.spyCount < 1 || args.spyCount > 3) {
      throw new ConvexError('Spy count must be 1–3.');
    }
    if (args.roundMinutes < 1 || args.roundMinutes > 15) {
      throw new ConvexError('Round minutes must be 1–15.');
    }
    if (args.roundCount < 1 || args.roundCount > 10) {
      throw new ConvexError('Round count must be 1–10.');
    }
    await ctx.db.patch(room._id, {
      config: {
        spyCount: args.spyCount,
        roundMinutes: args.roundMinutes,
        roundCount: args.roundCount,
      },
    });
  },
});

export const heartbeat = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) return;
    const player = await ctx.db
      .query('players')
      .withIndex('by_room_and_token', (q) =>
        q.eq('roomId', room._id).eq('clientToken', args.clientToken),
      )
      .first();
    if (player) {
      await ctx.db.patch(player._id, { lastSeenAt: Date.now() });
    }
  },
});

/**
 * Sanitized room snapshot delivered over the live subscription. Crucially,
 * the location is NOT included — leaking that field would defeat the
 * spy mechanic entirely.
 */
export const watchRoom = query({
  args: { code: v.string() },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) return null;

    const players = await getPlayers(ctx, room._id);
    let currentRound: any = null;
    let currentGame: any = null;
    if (room.currentGameId) {
      const game = await ctx.db.get(room.currentGameId);
      if (game) {
        currentGame = {
          _id: game._id,
          status: game.status,
          phase: game.phase ?? 'playing',
          nextRoundStartsAtMs: game.nextRoundStartsAtMs ?? null,
          currentRoundIndex: game.currentRoundIndex,
          totalRounds: game.totalRounds,
          usedLocationIds: game.usedLocationIds,
        };
        if (game.currentRoundId) {
          const round = await ctx.db.get(game.currentRoundId);
          if (round) {
            currentRound = {
              _id: round._id,
              index: round.index,
              startedAtMs: round.startedAtMs,
              endsAtMs: round.endsAtMs,
              status: round.status,
              endedReason: round.endedReason ?? null,
              // Note: locationId intentionally omitted.
            };
          }
        }
      }
    }

    return {
      _id: room._id,
      code: room.code,
      status: room.status,
      ownerToken: room.ownerToken,
      config: publicConfig(room),
      players: players
        .map((p) => ({
          _id: p._id,
          clientToken: p.clientToken,
          displayName: p.displayName,
          isReady: p.isReady,
          joinedAt: p.joinedAt,
          isOwner: p.clientToken === room.ownerToken,
        }))
        .sort((a, b) => a.joinedAt - b.joinedAt),
      currentGame,
      currentRound,
    };
  },
});
