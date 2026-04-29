import { v } from 'convex/values';

import { Id } from './_generated/dataModel';
import { MutationCtx, internalMutation } from './_generated/server';

const STALE_OWNER_THRESHOLD_MS = 60_000;
// How long after a game ends before we delete it. Gives players time to
// view the summary screen and disconnect.
const ENDED_GRACE_MS = 30 * 60 * 1000; // 30 minutes
// How long all players must be silent before we abandon a lobby/in-game
// room. Heartbeat is every 15s, so 60 min is safely conservative.
const OFFLINE_THRESHOLD_MS = 60 * 60 * 1000; // 60 minutes
// Empty rooms (no players, e.g. someone created and immediately closed
// the app) get reaped sooner.
const EMPTY_ROOM_TTL_MS = 10 * 60 * 1000; // 10 minutes

/**
 * Cascade-delete every record tied to a room: players, games, rounds, the
 * round's secrets + assignments, and finally the room itself.
 *
 * Idempotent: missing room is a no-op so the scheduled invocation is safe
 * even if the daily sweep already cleaned it up.
 */
async function cascadeDeleteRoom(
  ctx: MutationCtx,
  roomId: Id<'rooms'>,
): Promise<void> {
  const players = await ctx.db
    .query('players')
    .withIndex('by_room', (q) => q.eq('roomId', roomId))
    .collect();
  for (const p of players) {
    await ctx.db.delete(p._id);
  }

  const games = await ctx.db
    .query('games')
    .withIndex('by_room', (q) => q.eq('roomId', roomId))
    .collect();
  for (const game of games) {
    const rounds = await ctx.db
      .query('rounds')
      .withIndex('by_game', (q) => q.eq('gameId', game._id))
      .collect();
    for (const round of rounds) {
      const secrets = await ctx.db
        .query('roundSecrets')
        .withIndex('by_round', (q) => q.eq('roundId', round._id))
        .collect();
      for (const s of secrets) {
        await ctx.db.delete(s._id);
      }

      const assignments = await ctx.db
        .query('roundAssignments')
        .withIndex('by_round_and_token', (q) => q.eq('roundId', round._id))
        .collect();
      for (const a of assignments) {
        await ctx.db.delete(a._id);
      }

      await ctx.db.delete(round._id);
    }
    await ctx.db.delete(game._id);
  }

  const room = await ctx.db.get(roomId);
  if (room) await ctx.db.delete(roomId);
}

/**
 * Scheduled by `endRoundCore` when a game flips to `ended`. Verifies the
 * room is still ended (not somehow recycled), then nukes it. Also covers
 * the rare race where a player rejoined to view the summary — by the time
 * this fires they will have moved on.
 */
export const purgeRoom = internalMutation({
  args: { roomId: v.id('rooms') },
  handler: async (ctx, args) => {
    const room = await ctx.db.get(args.roomId);
    if (!room) return;
    await cascadeDeleteRoom(ctx, args.roomId);
  },
});

/**
 * Hourly safety net. Catches:
 *   - ended rooms whose scheduled purge somehow missed
 *   - lobbies / in-game rooms where everyone has gone silent
 *   - empty rooms left behind by failed creates
 *
 * Cheap to run because we have very few rooms; if this ever scales we'd
 * add a `lastActivityAt` field on rooms to filter by index.
 */
export const purgeStale = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const rooms = await ctx.db.query('rooms').collect();

    for (const room of rooms) {
      const players = await ctx.db
        .query('players')
        .withIndex('by_room', (q) => q.eq('roomId', room._id))
        .collect();

      const lastActivity = players.reduce(
        (max, p) => Math.max(max, p.lastSeenAt),
        room.createdAt,
      );
      const idleMs = now - lastActivity;

      let purge = false;

      if (players.length === 0) {
        purge = now - room.createdAt > EMPTY_ROOM_TTL_MS;
      } else if (room.status === 'ended') {
        purge = idleMs > ENDED_GRACE_MS;
      } else {
        purge = idleMs > OFFLINE_THRESHOLD_MS;
      }

      if (purge) {
        await cascadeDeleteRoom(ctx, room._id);
      }
    }
  },
});

/**
 * Sweep stranded child rows whose parent has been deleted (e.g. a room was
 * manually removed from the dashboard without cascading). Safe to run any
 * time — it only deletes rows whose foreign-key target is gone.
 *
 * Order matters: drop assignments + secrets first (point at rounds), then
 * rounds (point at games), then games (point at rooms), then orphan
 * players.
 */
export const purgeOrphans = internalMutation({
  args: {},
  handler: async (ctx) => {
    let deleted = {
      assignments: 0,
      secrets: 0,
      rounds: 0,
      games: 0,
      players: 0,
    };

    const assignments = await ctx.db.query('roundAssignments').collect();
    for (const a of assignments) {
      const round = await ctx.db.get(a.roundId);
      if (!round) {
        await ctx.db.delete(a._id);
        deleted.assignments++;
      }
    }

    const secrets = await ctx.db.query('roundSecrets').collect();
    for (const s of secrets) {
      const round = await ctx.db.get(s.roundId);
      if (!round) {
        await ctx.db.delete(s._id);
        deleted.secrets++;
      }
    }

    const rounds = await ctx.db.query('rounds').collect();
    for (const r of rounds) {
      const game = await ctx.db.get(r.gameId);
      if (!game) {
        await ctx.db.delete(r._id);
        deleted.rounds++;
      }
    }

    const games = await ctx.db.query('games').collect();
    for (const g of games) {
      const room = await ctx.db.get(g.roomId);
      if (!room) {
        await ctx.db.delete(g._id);
        deleted.games++;
      }
    }

    const players = await ctx.db.query('players').collect();
    for (const p of players) {
      const room = await ctx.db.get(p.roomId);
      if (!room) {
        await ctx.db.delete(p._id);
        deleted.players++;
      }
    }

    return deleted;
  },
});

/**
 * Existing job: transfer ownership in a lobby if the host has gone silent
 * but other players are still around, so the room doesn't get stuck.
 */
export const reapStaleOwners = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const lobbies = await ctx.db
      .query('rooms')
      .filter((q) => q.eq(q.field('status'), 'lobby'))
      .collect();

    for (const room of lobbies) {
      const players = await ctx.db
        .query('players')
        .withIndex('by_room', (q) => q.eq('roomId', room._id))
        .collect();
      if (players.length === 0) {
        await cascadeDeleteRoom(ctx, room._id);
        continue;
      }
      const owner = players.find((p) => p.clientToken === room.ownerToken);
      if (!owner || now - owner.lastSeenAt > STALE_OWNER_THRESHOLD_MS) {
        const next = [...players]
          .filter((p) => p.clientToken !== room.ownerToken)
          .sort((a, b) => a.joinedAt - b.joinedAt)[0];
        if (next) {
          await ctx.db.patch(room._id, { ownerToken: next.clientToken });
        }
      }
    }
  },
});
