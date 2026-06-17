import { v } from 'convex/values';

import { query } from './_generated/server';

/**
 * Verifies the developer unlock code entered behind the hidden 10-tap
 * gesture on the version label (see `welcome_screen.dart`). The expected
 * code lives in the `DEV_MODE_CODE` env var — set/rotate it with
 *   npx convex env set DEV_MODE_CODE <code>
 * so it can be changed without shipping a new build.
 *
 * The secret never crosses the wire: the client sends a candidate code and
 * receives only the boolean match. Returns `false` whenever the env var is
 * unset, so dev mode can never be unlocked by accident on a deployment that
 * was not explicitly configured for it.
 */
export const verifyDevCode = query({
  args: { code: v.string() },
  handler: async (_ctx, { code }) => {
    const expected = process.env.DEV_MODE_CODE ?? '';
    return expected.length > 0 && code === expected;
  },
});
