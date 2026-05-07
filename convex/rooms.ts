import { ConvexError, v } from 'convex/values';

import { Doc, Id } from './_generated/dataModel';
import {
  MutationCtx,
  QueryCtx,
  internalMutation,
  mutation,
  query,
} from './_generated/server';
import { triggerIntermissionCountdown } from './games';
import { generateRoomCode, isValidCode, normalizeCode } from './helpers/code';
import { cascadeDeleteRoom } from './maintenance';

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

function publicDisabledLocationIds(room: Doc<'rooms'>): string[] {
  return (room.disabledLocationIds ?? []).map((id) => id.toString());
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
      // Last person out — cascade the room and all child rows.
      await cascadeDeleteRoom(ctx, room._id);
      return;
    }

    if (room.ownerToken === args.clientToken && room.status === 'lobby') {
      // Transfer ownership to the player who joined earliest. The new host's
      // owned-bundle set is unknown server-side until their lobby listener
      // pushes it, so clear the stale list — non-hosts briefly see only the
      // free pack until that push lands.
      const next = [...remaining].sort((a, b) => a.joinedAt - b.joinedAt)[0];
      await ctx.db.patch(room._id, {
        ownerToken: next.clientToken,
        hostOwnedBundleSlugs: [],
      });
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

/**
 * Host-only. Replaces the room's `disabledLocationIds` set with the given
 * list. Called by the locations picker bottom-sheet in the lobby. Lobby-
 * only — once a game is running, the snapshot on `games.disabledLocationIds`
 * is what matters and editing here would have no effect on the live pool.
 *
 * Server doesn't validate that the IDs are actually locations the host
 * owns or that they exist; the picker UI is the source of truth and can
 * only present rows the user can see. An ID for a non-existent or
 * unowned location is harmless — it just never matches a row in the
 * filter.
 */
export const setDisabledLocations = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
    disabledLocationIds: v.array(v.id('locations')),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) throw new ConvexError('Room not found.');
    if (room.ownerToken !== args.clientToken) {
      throw new ConvexError('Only the host can change locations.');
    }
    if (room.status !== 'lobby') {
      throw new ConvexError('Cannot change locations during a game.');
    }
    await ctx.db.patch(room._id, {
      disabledLocationIds: args.disabledLocationIds,
    });
  },
});

/**
 * Host-only. Publishes the host's locally-owned bundle slugs to the room so
 * non-host players can render the same "active packs" chips in the lobby.
 * Server doesn't validate the slugs — ownership lives client-side
 * (SharedPreferences, RevenueCat later) and the picker UI decides what's
 * shown. Unknown or stale slugs are harmless: they just won't match any
 * `bundles` row when the chip is rendered.
 */
export const setHostOwnedBundleSlugs = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
    slugs: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) throw new ConvexError('Room not found.');
    if (room.ownerToken !== args.clientToken) {
      throw new ConvexError('Only the host can change active packs.');
    }
    if (room.status !== 'lobby') {
      throw new ConvexError('Cannot change active packs during a game.');
    }
    await ctx.db.patch(room._id, {
      hostOwnedBundleSlugs: args.slugs,
    });
  },
});

/**
 * Idempotent. Stores per-player push tokens used by the round-end fan-out
 * action (`internal.notifications.dispatchRoundEndedPush`).
 *
 *  - `pushTokenApnsLiveActivity` is a per-Live-Activity APNs token; it is
 *    re-emitted by ActivityKit each time a new activity starts, so we
 *    overwrite on every call. We don't unset it here; the dispatcher
 *    clears it on 410 Gone / 400 BadDeviceToken and the next activity
 *    will re-register.
 *  - `pushTokenFcm` is a per-device FCM token; persists across rounds.
 *  - `locale` is the device UI language; lets the server localize the
 *    "Round ended" body before sending.
 *
 * `undefined` for any field means "leave alone" — callers that only
 * have one of the three values (e.g. iOS sending only the LA token,
 * Android sending only FCM) don't accidentally clobber the others.
 *
 * No-op if the player isn't in the room (e.g. they already left).
 */
export const registerPushTokens = mutation({
  args: {
    code: v.string(),
    clientToken: v.string(),
    pushTokenApnsLiveActivity: v.optional(v.string()),
    pushTokenFcm: v.optional(v.string()),
    locale: v.optional(v.union(v.literal('en'), v.literal('tr'))),
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
    if (!player) return;

    const patch: Partial<Doc<'players'>> = {};
    if (args.pushTokenApnsLiveActivity !== undefined) {
      patch.pushTokenApnsLiveActivity = args.pushTokenApnsLiveActivity;
      patch.pushTokenApnsUpdatedAt = Date.now();
    }
    if (args.pushTokenFcm !== undefined) {
      patch.pushTokenFcm = args.pushTokenFcm;
    }
    if (args.locale !== undefined) {
      patch.locale = args.locale;
    }
    if (Object.keys(patch).length === 0) return;
    await ctx.db.patch(player._id, patch);
  },
});

/**
 * Internal helper used by the push dispatcher to clear a per-player token
 * after APNs/FCM tells us it's invalid (410 Gone, 400 BadDeviceToken,
 * UNREGISTERED, INVALID_ARGUMENT). Plain helper so the action can call
 * `runMutation(internal.rooms.clearInvalidPushToken, ...)`.
 */
export const clearInvalidPushToken = internalMutation({
  args: {
    playerId: v.id('players'),
    field: v.union(
      v.literal('pushTokenApnsLiveActivity'),
      v.literal('pushTokenFcm'),
    ),
  },
  handler: async (ctx, args) => {
    const player = await ctx.db.get(args.playerId);
    if (!player) return;
    const patch: Partial<Doc<'players'>> = {};
    if (args.field === 'pushTokenApnsLiveActivity') {
      patch.pushTokenApnsLiveActivity = undefined;
      patch.pushTokenApnsUpdatedAt = undefined;
    } else {
      patch.pushTokenFcm = undefined;
    }
    await ctx.db.patch(args.playerId, patch);
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

    // Derive which packs have ≥1 enabled location given the host's owned set
    // and the room's disabled list. Computed here so every subscriber sees
    // the same chip strip and Convex re-runs the query whenever either input
    // changes — clients don't need to fetch picker locations themselves.
    const ownedSet = new Set(room.hostOwnedBundleSlugs ?? []);
    const disabledSet = new Set(
      (room.disabledLocationIds ?? []).map((id) => id.toString()),
    );
    const allLocations = await ctx.db.query('locations').collect();
    let freePackActive = false;
    const activeSlugs = new Set<string>();
    let enabledLocationCount = 0;
    let totalLocationCount = 0;
    for (const loc of allLocations) {
      const slug = loc.bundleSlug;
      if (slug != null && !ownedSet.has(slug)) continue;
      // In the room's pool — count it toward the total before the disabled
      // filter so non-host clients can show the "X / Y" progress badge.
      totalLocationCount++;
      if (disabledSet.has(loc._id.toString())) continue;
      enabledLocationCount++;
      if (slug == null) freePackActive = true;
      else activeSlugs.add(slug);
    }

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
          lastSpyRevealRoundIndex: game.lastSpyRevealRoundIndex ?? null,
          lastSpyClientToken: game.lastSpyClientToken ?? null,
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
      serverNowMs: Date.now(),
      status: room.status,
      ownerToken: room.ownerToken,
      config: publicConfig(room),
      disabledLocationIds: publicDisabledLocationIds(room),
      hostOwnedBundleSlugs: room.hostOwnedBundleSlugs ?? [],
      activePackSlugs: [...activeSlugs],
      freePackActive,
      enabledLocationCount,
      totalLocationCount,
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

const LOCALE_VALIDATOR = v.optional(v.union(v.literal('en'), v.literal('tr')));

/**
 * Locale-projected list of locations the host has *enabled* for this room.
 * Read-only mirror of the picker for non-host players: lets everyone see
 * exactly which locations are in play, live as the host toggles. Reuses
 * the room's published `hostOwnedBundleSlugs` so non-hosts don't need to
 * pass the host's owned set themselves. Returns [] if the room is gone.
 */
export const enabledLocationsForRoom = query({
  args: { code: v.string(), locale: LOCALE_VALIDATOR },
  handler: async (ctx, args) => {
    const code = normalizeCode(args.code);
    const room = await findRoomByCode(ctx, code);
    if (!room) return [];
    const ownedSet = new Set(room.hostOwnedBundleSlugs ?? []);
    const disabledSet = new Set(
      (room.disabledLocationIds ?? []).map((id) => id.toString()),
    );
    const all = await ctx.db.query('locations').collect();
    const eligibleEnabled = all.filter(
      (l) =>
        (l.bundleSlug == null || ownedSet.has(l.bundleSlug)) &&
        !disabledSet.has(l._id.toString()),
    );
    return eligibleEnabled.map((l) => {
      const localized =
        args.locale === 'tr' && l.translations?.tr
          ? l.translations.tr.name
          : l.name;
      return {
        _id: l._id,
        name: localized,
        bundleSlug: l.bundleSlug ?? null,
      };
    });
  },
});
