import { cronJobs } from 'convex/server';
import { internal } from './_generated/api';

const crons = cronJobs();

// Transfer ownership in a lobby if the host goes silent so the room
// doesn't get stuck waiting on someone who's gone.
crons.interval(
  'reap stale owners',
  { seconds: 60 },
  internal.maintenance.reapStaleOwners,
);

// Hourly safety net: cascade-delete ended rooms past their grace period,
// abandoned lobbies / in-game rooms where everyone has gone silent, and
// empty rooms left over from failed creates.
crons.interval(
  'purge stale rooms',
  { hours: 1 },
  internal.maintenance.purgeStale,
);

// Daily belt-and-braces sweep for child rows whose parent disappeared
// without cascading (e.g. a manual dashboard delete, or a future schema
// change that adds a child table the cascade forgot about).
crons.interval(
  'purge orphan rows',
  { hours: 24 },
  internal.maintenance.purgeOrphans,
);

export default crons;
