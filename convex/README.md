# Convex backend — "Where am I?"

This project uses **self-hosted Convex** (deployment at
`https://spyfall-api.walhallaa.dpdns.org`), not Convex Cloud. The deploy
flow uses `CONVEX_SELF_HOSTED_URL` + `CONVEX_SELF_HOSTED_ADMIN_KEY`
instead of the cloud-mode `CONVEX_DEPLOYMENT` variable.

> **Run all `convex` commands from the project root** (one level up from
> here). The CLI looks for a `convex/` subdirectory of the cwd; if you run
> it from inside `convex/` it'll create a nested `convex/convex/` and
> deploy nothing.

## First-time setup

1. Get the admin key. On the machine hosting the Convex backend (behind
   the URL above), run:

   ```bash
   ./generate_admin_key.sh
   ```

   It prints a long key starting with `convex-self-hosted|...`. Copy it.

2. From the **project root**, copy the env template and fill in the key:

   ```bash
   cp .env.local.example .env.local
   # edit .env.local — paste the admin key into CONVEX_SELF_HOSTED_ADMIN_KEY
   ```

3. Install dependencies (from the project root):

   ```bash
   npm install
   ```

## Deploy

From the project root:

```bash
npx convex deploy                  # pushes schema + functions
npx convex run locations:seed      # one-time: seeds the 24 locations
```

For iterating during development with hot-reload:

```bash
npx convex dev
```

Other useful commands:

```bash
npx convex logs           # tail backend logs
npx convex dashboard      # open the dashboard for this deployment
```

## Layout

| File | Purpose |
|------|---------|
| `schema.ts` | Tables + indexes |
| `rooms.ts` | createRoom, joinRoom, leaveRoom, setReady, updateConfig, heartbeat, watchRoom |
| `games.ts` | startGame, endRoundManual, endRoundIfDue, endRoundInternal, serverNow, getMyRole, watchLocations |
| `locations.ts` | seed (internal), list |
| `maintenance.ts` | reapStaleOwners |
| `crons.ts` | scheduled jobs |
| `helpers/code.ts` | 4-char unique-code generator |
| `helpers/assign.ts` | spy + role assignment |

## Trust model

There is no auth. Each device generates a UUID v4 (`clientToken`) and
sends it as an explicit argument on every mutation/query. Functions trust
the supplied token. The token is **never** placed in invite links; only
the 4-character room code is shareable.

## Why secret data lives in `roundSecrets`

`watchRoom` is subscribed by every player including the spy. If
`locationId` were on the `rounds` row, it would be sent to every
subscriber over the websocket — defeating the spy mechanic. Instead the
location lives in `roundSecrets` (1:1 with `rounds`) and is only readable
from server-side internal functions. The only client-visible place a
location can appear is through `getMyRole`, which filters by the caller's
`clientToken` and is the caller's *own* assignment.
