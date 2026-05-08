import { v } from 'convex/values';

import { mutation } from './_generated/server';

/**
 * Append-only log for client-side Live Activity push-token failures. Called
 * by the iOS Dart layer when `Activity.request(pushType: .token)` throws —
 * masking that failure (the previous "fall back to pushType: nil" behavior)
 * shipped a Live Activity that could never be updated by the server, and
 * we never knew. Bounded by a periodic prune in `maintenance.purgeOldDiagnostics`.
 *
 * Public mutation by design: clients can write a single short row at most
 * once per round-start, and the data is non-sensitive (no tokens, no PII).
 */
export const logLiveActivityFailure = mutation({
  args: {
    code: v.string(),
    message: v.string(),
    roomCode: v.optional(v.string()),
    osVersion: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const code = args.code.slice(0, 64);
    const message = args.message.slice(0, 512);
    await ctx.db.insert('liveActivityFailures', {
      code,
      message,
      atMs: Date.now(),
      roomCode: args.roomCode?.slice(0, 16),
      osVersion: args.osVersion?.slice(0, 32),
    });
  },
});
