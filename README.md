# Where am I?

A Spyfall-style mobile party game. One of you is the spy. Everyone else
shares a secret location. Ask careful questions, blend in, and figure out
who doesn't belong.

- 3–12 players, no accounts, pass-and-play friendly.
- 4-character room codes (no ambiguous glyphs).
- Configurable spies (1–3), round length (1–15 min), and round count (1–10).
- Server-authoritative countdown — locking the screen or backgrounding the
  app does not desync the timer.
- Local notifications fire when a round ends, even if the app is suspended.

## Stack

- Flutter + Riverpod + go_router (clean architecture: data / domain / presentation)
- Convex backend (`convex_flutter` — websocket subscriptions, mutations, scheduler)
- Hand-typed Convex DTOs (no Dart codegen for Convex yet)

## First-time setup

The Flutter app ships with the hosted deployment URL baked in
(`https://spyfall-api.walhallaa.dpdns.org`), so the simplest path is:

```bash
flutter pub get
flutter run
```

To point at a different deployment:

```bash
flutter run --dart-define=CONVEX_URL=https://<other-deployment>
```

To run the Convex backend yourself (for development):

```bash
# from the project root (NOT from inside convex/):
npm install
npx convex dev                   # watches for changes & pushes
npx convex run locations:seed    # one-time seed (in a second terminal)
```

> The `convex` CLI looks for a `convex/` subdirectory of your cwd. Always
> run these commands from the project root; running from inside `convex/`
> would make it create a useless nested `convex/convex/` project.

## Tests

```bash
flutter test
```

Covered:

- 4-char code generator: alphabet purity, uniformity, ambiguity exclusion.
- Spy + role assignment invariants.
- Countdown derivation (background/resume scenarios).

## Project layout

```
lib/
  core/                      # theme, router, storage, convex bootstrap, lifecycle, notifications
  features/
    identity/                # welcome screen
    room/                    # home (create/join), lobby
    game/                    # round, role card, location grid, summary
convex/
  schema.ts                  # tables + indexes
  rooms.ts                   # createRoom, joinRoom, leaveRoom, setReady, updateConfig, heartbeat, watchRoom
  games.ts                   # startGame, endRoundManual, endRoundIfDue, getMyRole, watchLocations, serverNow
  locations.ts               # seed, list (24 original generic venues)
  maintenance.ts             # reapStaleOwners
  crons.ts
  helpers/code.ts            # 4-char unique-code generator
  helpers/assign.ts          # spy + role assignment
```

## How spy secrecy is enforced

Convex subscriptions deliver whatever the server function returns. Public
queries (`watchRoom`, `watchLocations`) are deliberately stripped of
`locationId` and role data. The location for a round lives in a separate
`roundSecrets` table, accessible only to internal Convex functions. The
only client-visible place a location appears is `getMyRole`, which filters
by the caller's `clientToken` — so a spy subscribing to it gets back
`{role: "spy", location: null}` and cannot ask for someone else's role.

## How the countdown survives backgrounding

- The server stamps `endsAtMs` on every round (server clock).
- On connect / on resume, the client calls `serverNow()` and stores
  `offset = serverMs - localMs`.
- The UI computes `remaining = endsAtMs - (DateTime.now() + offset)` —
  the deadline never moves, so locking the screen and reopening yields
  the correct number on first paint.
- A 1Hz `Ticker` triggers re-derivation only for visual smoothness.
- A local notification is scheduled at `endsAtMs` so the user is pinged
  if the app is suspended.
- Round-end is server-authoritative: Convex's `ctx.scheduler.runAfter`
  flips the round and picks the next location. Any client whose local
  clock has passed the deadline opportunistically calls the idempotent
  `endRoundIfDue` mutation as a belt-and-braces safety net.
