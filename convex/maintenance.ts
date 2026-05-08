import { v } from 'convex/values';

import { Id } from './_generated/dataModel';
import { MutationCtx, internalMutation } from './_generated/server';

const STALE_OWNER_THRESHOLD_MS = 60_000;
// How long after a game ends before we delete it. Gives players time to
// view the summary screen and disconnect.
const ENDED_GRACE_MS = 30 * 60 * 1000; // 30 minutes
// How long all players must be silent before we abandon a lobby/in-game
// room. Heartbeat is every 15s, so 90s = 6 missed beats of grace.
const OFFLINE_THRESHOLD_MS = 90 * 1000; // 90 seconds
// Empty rooms (no players, e.g. someone created and immediately closed
// the app) get reaped almost immediately.
const EMPTY_ROOM_TTL_MS = 60 * 1000; // 60 seconds

/**
 * Cascade-delete every record tied to a room: players, games, rounds, the
 * round's secrets + assignments, and finally the room itself.
 *
 * Idempotent: missing room is a no-op so the scheduled invocation is safe
 * even if the daily sweep already cleaned it up.
 */
export async function cascadeDeleteRoom(
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
 * Order is top-down by ancestry so cascading orphans are caught in a
 * single pass: a deleted `games` row in step 1 makes its `rounds` look
 * orphaned in step 2, which in turn makes its `secrets`/`assignments`
 * look orphaned in steps 3-4. Convex makes mid-mutation deletes visible
 * to later `ctx.db.get` calls in the same transaction, which is what
 * makes this work.
 */
export const purgeOrphans = internalMutation({
  args: {},
  handler: async (ctx) => {
    let deleted = {
      games: 0,
      rounds: 0,
      secrets: 0,
      assignments: 0,
      players: 0,
    };

    const games = await ctx.db.query('games').collect();
    for (const g of games) {
      const room = await ctx.db.get(g.roomId);
      if (!room) {
        await ctx.db.delete(g._id);
        deleted.games++;
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

    const secrets = await ctx.db.query('roundSecrets').collect();
    for (const s of secrets) {
      const round = await ctx.db.get(s.roundId);
      if (!round) {
        await ctx.db.delete(s._id);
        deleted.secrets++;
      }
    }

    const assignments = await ctx.db.query('roundAssignments').collect();
    for (const a of assignments) {
      const round = await ctx.db.get(a.roundId);
      if (!round) {
        await ctx.db.delete(a._id);
        deleted.assignments++;
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
 * Prune old `liveActivityFailures` rows. Bounded log written by the iOS
 * Dart layer when ActivityKit fails to issue a push token; we keep a
 * one-week window so we can spot spikes without unbounded growth.
 */
const LIVE_ACTIVITY_FAILURE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

export const purgeOldDiagnostics = internalMutation({
  args: {},
  handler: async (ctx) => {
    const cutoff = Date.now() - LIVE_ACTIVITY_FAILURE_TTL_MS;
    const stale = await ctx.db
      .query('liveActivityFailures')
      .withIndex('by_atMs', (q) => q.lt('atMs', cutoff))
      .collect();
    for (const row of stale) {
      await ctx.db.delete(row._id);
    }
    return { deleted: stale.length };
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
