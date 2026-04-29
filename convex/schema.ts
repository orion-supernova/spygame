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

  locations: defineTable({
    name: v.string(),
    roles: v.array(v.string()),
  }),
});
