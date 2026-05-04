import { defineSchema, defineTable } from 'convex/server';
import { v } from 'convex/values';

/**
 * "Where am I?" — Spyfall-style mobile game.
 *
 * Trust model: there is no auth. Each device generates a random `clientToken`
 * (UUID v4) which is treated as a bearer secret. Functions trust whatever
 * token they're given. Public queries return only sanitized projections —
 * `locationId` and role assignments are NEVER exposed by a subscribed
 * query because that would leak the location to the spy.
 */
export default defineSchema({
  rooms: defineTable({
    code: v.string(), // Always uppercase. Unique via the index below.
    ownerToken: v.string(),
    status: v.union(
      v.literal('lobby'),
      v.literal('inGame'),
      v.literal('ended'),
    ),
    config: v.object({
      spyCount: v.number(),
      roundMinutes: v.number(),
      roundCount: v.number(),
    }),
    currentGameId: v.optional(v.id('games')),
    // Host-curated blacklist of locations that should NOT show up in the
    // next game from this room. Persists across games (host's preference
    // carries over). Snapshotted onto `games.disabledLocationIds` at
    // startGame so mid-game edits don't change the running pool.
    disabledLocationIds: v.optional(v.array(v.id('locations'))),
    createdAt: v.number(),
  })
    .index('by_code', ['code']),

  players: defineTable({
    roomId: v.id('rooms'),
    clientToken: v.string(),
    displayName: v.string(),
    isReady: v.boolean(),
    joinedAt: v.number(),
    lastSeenAt: v.number(),
  })
    .index('by_room', ['roomId'])
    .index('by_room_and_token', ['roomId', 'clientToken']),

  games: defineTable({
    roomId: v.id('rooms'),
    status: v.union(v.literal('active'), v.literal('ended')),
    // Sub-state of an active game. Optional for backward-compat with rows
    // created before this field existed; treat undefined as 'playing'.
    //  - 'playing'   — a round is in progress
    //  - 'between'   — round just ended; waiting for everyone to tap Ready
    //  - 'starting'  — all ready, 3-second countdown until the next round
    //  - 'ended'     — game is over (mirrors status='ended')
    phase: v.optional(
      v.union(
        v.literal('playing'),
        v.literal('between'),
        v.literal('starting'),
        v.literal('ended'),
      ),
    ),
    nextRoundStartsAtMs: v.optional(v.number()),
    currentRoundIndex: v.number(),
    totalRounds: v.number(),
    usedLocationIds: v.array(v.id('locations')),
    currentRoundId: v.optional(v.id('rounds')),
    // Bundle slugs the host claimed to own at game-start. Snapshotted so
    // the location pool stays stable across rounds even if mid-game
    // mutations would change the host's ownership. Optional for
    // backward-compat with games created before this field existed; the
    // server treats `undefined` as "free locations only".
    ownedBundleSlugs: v.optional(v.array(v.string())),
    // Snapshot of `rooms.disabledLocationIds` at game-start. Treated the
    // same way ownedBundleSlugs is — frozen at startGame, never edited
    // mid-game. Optional for backward-compat (treat undefined as []).
    disabledLocationIds: v.optional(v.array(v.id('locations'))),
  })
    .index('by_room', ['roomId']),

  rounds: defineTable({
    gameId: v.id('games'),
    index: v.number(),
    startedAtMs: v.number(),
    endsAtMs: v.number(),
    status: v.union(v.literal('active'), v.literal('ended')),
    endedReason: v.optional(
      v.union(v.literal('timer'), v.literal('manual')),
    ),
  })
    .index('by_game', ['gameId']),

  // 1:1 with rounds. NEVER exposed by a public query — the spy would see
  // the location. Read only by internal Convex functions.
  roundSecrets: defineTable({
    roundId: v.id('rounds'),
    locationId: v.id('locations'),
  })
    .index('by_round', ['roundId']),

  roundAssignments: defineTable({
    roundId: v.id('rounds'),
    clientToken: v.string(),
    role: v.string(), // "spy" | "<role-at-location>"
  })
    .index('by_round_and_token', ['roundId', 'clientToken']),

  // `name` and `roles` are the canonical English values. `translations` is
  // optional and added per locale; missing entries fall back to English on
  // read. Role array length and ORDER must match `roles` exactly — server
  // looks up role index in English to project the localized variant.
  //
  // `bundleSlug` is undefined for the free location set and set to a
  // bundle's slug for paid-pack locations. The location pool at game start
  // = free + locations whose bundleSlug is in the host's owned set.
  locations: defineTable({
    name: v.string(),
    roles: v.array(v.string()),
    bundleSlug: v.optional(v.string()),
    translations: v.optional(
      v.object({
        tr: v.optional(
          v.object({
            name: v.string(),
            roles: v.array(v.string()),
          }),
        ),
      }),
    ),
  }).index('by_bundle', ['bundleSlug']),

  // Static catalog of paid location packs. Server is the source of truth
  // for which slugs exist and which locations belong to each. Real
  // ownership is tracked client-side (SharedPreferences) and will move to
  // RevenueCat entitlements later — server does not validate ownership
  // claims because there are no accounts.
  bundles: defineTable({
    slug: v.string(),
    category: v.union(v.literal('city'), v.literal('theme')),
    sortOrder: v.number(),
    priceUsd: v.string(), // display only, e.g. "$1.99"
    accentHex: v.string(), // tile/accent color, e.g. "#FFB02E"
    iconKey: v.string(), // client maps this to a Material icon
    translations: v.object({
      en: v.object({ title: v.string(), tagline: v.string() }),
      tr: v.object({ title: v.string(), tagline: v.string() }),
    }),
  }).index('by_slug', ['slug']),
});
