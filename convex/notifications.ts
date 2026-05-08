'use node';

import { v } from 'convex/values';
import http2 from 'node:http2';
import { SignJWT, importPKCS8 } from 'jose';

import { internal } from './_generated/api';
import { Id } from './_generated/dataModel';
import { internalAction } from './_generated/server';

const APNS_HOST_PROD = 'https://api.push.apple.com';
const APNS_HOST_DEV = 'https://api.development.push.apple.com';

// Apple lets a JWT live up to 60 minutes; rotate at 50 to give ourselves
// slack and avoid the rate-limited "rotate too fast" floor (~20 min).
const APNS_JWT_TTL_MS = 50 * 60 * 1000;
const APNS_JWT_FLOOR_MS = 20 * 60 * 1000;

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const FCM_TOKEN_TTL_BUFFER_MS = 5 * 60 * 1000;

const PUSH_DISMISSAL_AFTER_S = 30;

type Locale = 'en' | 'tr';
type ApnsGateway = 'prod' | 'dev';

interface PushTarget {
  playerId: Id<'players'>;
  apnsLiveActivityToken?: string;
  apnsGateway?: ApnsGateway;
  fcmToken?: string;
  locale: Locale;
}

interface LocalizedPayload {
  endedLabel: string;
  pushTitle: string;
  pushBody: string;
}

const STRINGS: Record<Locale, {
  endedLabel: string;
  pushTitle: string;
  pushBodyTimer: (i: number) => string;
  pushBodyManual: (i: number) => string;
  pushBodyGameEnded: string;
}> = {
  en: {
    endedLabel: 'Round ended',
    pushTitle: 'Round ended',
    pushBodyTimer: (i) => `Round ${i} ended`,
    pushBodyManual: (i) => `Host ended round ${i}`,
    pushBodyGameEnded: 'Game over — see results',
  },
  tr: {
    endedLabel: 'Tur bitti',
    pushTitle: 'Tur bitti',
    pushBodyTimer: (i) => `${i}. tur sona erdi`,
    pushBodyManual: (i) => `Sunucu ${i}. turu bitirdi`,
    pushBodyGameEnded: 'Oyun bitti — sonuçlara bak',
  },
};

function localizeFor(
  locale: Locale,
  args: {
    roundIndex: number;
    endedReason: 'timer' | 'manual';
    gameEnded: boolean;
  },
): LocalizedPayload {
  const s = STRINGS[locale] ?? STRINGS.en;
  const body = args.gameEnded
    ? s.pushBodyGameEnded
    : args.endedReason === 'manual'
      ? s.pushBodyManual(args.roundIndex)
      : s.pushBodyTimer(args.roundIndex);
  return { endedLabel: s.endedLabel, pushTitle: s.pushTitle, pushBody: body };
}

// ---------- APNs JWT cache ----------

let cachedApnsJwt: { token: string; signedAtMs: number } | null = null;

async function getApnsJwt(): Promise<string | null> {
  const keyId = process.env.APNS_KEY_ID;
  const teamId = process.env.APNS_TEAM_ID;
  const p8 = process.env.APNS_AUTH_KEY_P8;
  if (!keyId || !teamId || !p8) return null;

  const now = Date.now();
  if (cachedApnsJwt && now - cachedApnsJwt.signedAtMs < APNS_JWT_TTL_MS) {
    return cachedApnsJwt.token;
  }
  // Apple rate-limits regenerating the JWT faster than ~once per 20 min.
  // If we just refreshed, return the cached one even if forced.
  if (
    cachedApnsJwt &&
    now - cachedApnsJwt.signedAtMs < APNS_JWT_FLOOR_MS
  ) {
    return cachedApnsJwt.token;
  }

  const privateKey = await importPKCS8(p8, 'ES256');
  const token = await new SignJWT({})
    .setProtectedHeader({ alg: 'ES256', kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt()
    .sign(privateKey);
  cachedApnsJwt = { token, signedAtMs: now };
  return token;
}

function invalidateApnsJwt(): void {
  // Force refresh on next getApnsJwt() (subject to the 20-min floor).
  cachedApnsJwt = null;
}

// ---------- APNs HTTP/2 client ----------

interface ApnsResult {
  status: number;
  reason?: string;
}

function defaultApnsGateway(): ApnsGateway {
  // `APNS_USE_SANDBOX=true` for development builds running against Apple's
  // sandbox APNs gateway; default to production.
  return process.env.APNS_USE_SANDBOX === 'true' ? 'dev' : 'prod';
}

function apnsHostFor(gateway: ApnsGateway): string {
  return gateway === 'dev' ? APNS_HOST_DEV : APNS_HOST_PROD;
}

async function sendApnsLiveActivityEnd(args: {
  deviceToken: string;
  bundleId: string;
  jwt: string;
  contentState: Record<string, unknown>;
  collapseId: string;
  gateway: ApnsGateway;
}): Promise<ApnsResult> {
  return new Promise((resolve, reject) => {
    const client = http2.connect(apnsHostFor(args.gateway));
    let settled = false;
    const finish = (r: ApnsResult | Error) => {
      if (settled) return;
      settled = true;
      try { client.close(); } catch { /* ignore */ }
      if (r instanceof Error) reject(r);
      else resolve(r);
    };
    client.on('error', (err) => finish(err));

    const nowSec = Math.floor(Date.now() / 1000);
    const payload = JSON.stringify({
      aps: {
        timestamp: nowSec,
        event: 'end',
        'content-state': args.contentState,
        'dismissal-date': nowSec + PUSH_DISMISSAL_AFTER_S,
      },
    });

    const req = client.request({
      ':method': 'POST',
      ':path': `/3/device/${args.deviceToken}`,
      'apns-topic': `${args.bundleId}.push-type.liveactivity`,
      'apns-push-type': 'liveactivity',
      'apns-priority': '10',
      'apns-expiration': String(nowSec + 60),
      'apns-collapse-id': args.collapseId,
      authorization: `bearer ${args.jwt}`,
      'content-type': 'application/json',
      'content-length': String(Buffer.byteLength(payload)),
    });
    req.setEncoding('utf8');

    let status = 0;
    let body = '';
    req.on('response', (headers) => {
      status = Number(headers[':status'] ?? 0);
    });
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      let reason: string | undefined;
      if (body) {
        try { reason = JSON.parse(body)?.reason; } catch { /* ignore */ }
      }
      finish({ status, reason });
    });
    req.on('error', (err) => finish(err));
    req.end(payload);
  });
}

// ---------- FCM v1 OAuth + send ----------

let cachedFcmToken: { token: string; expiresAtMs: number } | null = null;

interface FcmServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

function loadFcmServiceAccount(): FcmServiceAccount | null {
  const raw = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  try {
    const j = JSON.parse(raw) as FcmServiceAccount;
    if (!j.client_email || !j.private_key || !j.project_id) return null;
    return j;
  } catch {
    return null;
  }
}

async function getFcmAccessToken(
  account: FcmServiceAccount,
): Promise<string | null> {
  const now = Date.now();
  if (
    cachedFcmToken &&
    cachedFcmToken.expiresAtMs - FCM_TOKEN_TTL_BUFFER_MS > now
  ) {
    return cachedFcmToken.token;
  }
  const privateKey = await importPKCS8(account.private_key, 'RS256');
  const jwt = await new SignJWT({ scope: FCM_SCOPE })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(account.client_email)
    .setSubject(account.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(privateKey);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  });
  if (!res.ok) {
    console.error('[push] FCM OAuth failed', res.status, await res.text());
    return null;
  }
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cachedFcmToken = {
    token: data.access_token,
    expiresAtMs: now + data.expires_in * 1000,
  };
  return data.access_token;
}

interface FcmResult {
  status: number;
  errorCode?: string;
}

async function sendFcmRoundEnded(args: {
  account: FcmServiceAccount;
  accessToken: string;
  fcmToken: string;
  data: Record<string, string>;
}): Promise<FcmResult> {
  const url = `https://fcm.googleapis.com/v1/projects/${args.account.project_id}/messages:send`;
  const body = JSON.stringify({
    message: {
      token: args.fcmToken,
      data: args.data,
      android: { priority: 'HIGH' },
    },
  });
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${args.accessToken}`,
      'content-type': 'application/json',
    },
    body,
  });
  let errorCode: string | undefined;
  if (!res.ok) {
    try {
      const j = await res.json() as {
        error?: {
          details?: Array<{ '@type'?: string; errorCode?: string }>;
          status?: string;
        };
      };
      errorCode = j.error?.details?.find((d) => d.errorCode)?.errorCode
        ?? j.error?.status;
    } catch { /* ignore */ }
  }
  return { status: res.status, errorCode };
}

// ---------- The action ----------

export const dispatchRoundEndedPush = internalAction({
  args: {
    targets: v.array(
      v.object({
        playerId: v.id('players'),
        apnsLiveActivityToken: v.optional(v.string()),
        apnsGateway: v.optional(
          v.union(v.literal('prod'), v.literal('dev')),
        ),
        fcmToken: v.optional(v.string()),
        locale: v.union(v.literal('en'), v.literal('tr')),
      }),
    ),
    roundId: v.id('rounds'),
    roundIndex: v.number(),
    endedReason: v.union(v.literal('timer'), v.literal('manual')),
    gameEnded: v.boolean(),
  },
  handler: async (ctx, args) => {
    const targets = args.targets as PushTarget[];
    if (targets.length === 0) return;

    const apnsBundle = process.env.APNS_BUNDLE_ID;
    const apnsTargets = apnsBundle
      ? targets.filter((t) => t.apnsLiveActivityToken)
      : [];
    const fcmTargets = targets.filter((t) => t.fcmToken);

    // Resolve credentials in parallel.
    const [apnsJwt, fcmAccount] = await Promise.all([
      apnsTargets.length > 0 ? getApnsJwt() : Promise.resolve(null),
      fcmTargets.length > 0 ? Promise.resolve(loadFcmServiceAccount()) : Promise.resolve(null),
    ]);

    const fcmAccessToken = fcmAccount
      ? await getFcmAccessToken(fcmAccount)
      : null;

    // Dispatch all pushes in parallel; cleanup happens per-result.
    const work: Promise<unknown>[] = [];

    if (apnsJwt && apnsBundle) {
      const fallbackDefault = defaultApnsGateway();
      for (const t of apnsTargets) {
        const localized = localizeFor(t.locale, {
          roundIndex: args.roundIndex,
          endedReason: args.endedReason,
          gameEnded: args.gameEnded,
        });
        const contentState = {
          endsAtMs: Date.now(),
          title: localized.pushTitle,
          subtitle: localized.pushBody,
          endedLabel: localized.endedLabel,
        };
        // Per-token gateway: prefer the previously-discovered one; otherwise
        // fall back to the env default. On `BadDeviceToken`, retry the
        // other gateway once. APNs tokens are environment-bound: a token
        // issued for the sandbox APNs server is rejected by prod and vice
        // versa, so this auto-fallback unblocks TestFlight/dev builds whose
        // tokens don't match the server's APNS_USE_SANDBOX setting.
        const primary: ApnsGateway = t.apnsGateway ?? fallbackDefault;
        const secondary: ApnsGateway = primary === 'prod' ? 'dev' : 'prod';
        work.push(
          (async () => {
            try {
              let result = await sendApnsLiveActivityEnd({
                deviceToken: t.apnsLiveActivityToken!,
                bundleId: apnsBundle,
                jwt: apnsJwt,
                contentState,
                collapseId: `round-end-${args.roundId}`,
                gateway: primary,
              });
              let workingGateway: ApnsGateway = primary;
              const wasBadDeviceToken =
                result.status === 400 && result.reason === 'BadDeviceToken';
              if (wasBadDeviceToken) {
                // Retry against the other gateway. If THIS one still says
                // BadDeviceToken, the token is genuinely dead and we fall
                // through to the cleanup branch below.
                result = await sendApnsLiveActivityEnd({
                  deviceToken: t.apnsLiveActivityToken!,
                  bundleId: apnsBundle,
                  jwt: apnsJwt,
                  contentState,
                  collapseId: `round-end-${args.roundId}`,
                  gateway: secondary,
                });
                workingGateway = secondary;
              }
              if (result.status === 401) {
                // JWT rejected; force refresh on next call.
                invalidateApnsJwt();
                console.error('[push] APNs 401', result.reason);
              } else if (
                result.status === 410 ||
                (result.status === 400 && result.reason === 'BadDeviceToken')
              ) {
                await ctx.runMutation(
                  internal.rooms.clearInvalidPushToken,
                  { playerId: t.playerId, field: 'pushTokenApnsLiveActivity' },
                );
              } else if (result.status >= 200 && result.status < 300) {
                // Persist the gateway we actually delivered through so the
                // next push hits the right one on the first try.
                if (t.apnsGateway !== workingGateway) {
                  await ctx.runMutation(
                    internal.rooms.setApnsGateway,
                    { playerId: t.playerId, gateway: workingGateway },
                  );
                }
              } else if (result.status >= 400) {
                console.error('[push] APNs error', result.status, result.reason);
              }
            } catch (err) {
              console.error('[push] APNs threw', err);
            }
          })(),
        );
      }
    }

    if (fcmAccount && fcmAccessToken) {
      for (const t of fcmTargets) {
        const localized = localizeFor(t.locale, {
          roundIndex: args.roundIndex,
          endedReason: args.endedReason,
          gameEnded: args.gameEnded,
        });
        work.push(
          (async () => {
            try {
              const result = await sendFcmRoundEnded({
                account: fcmAccount,
                accessToken: fcmAccessToken,
                fcmToken: t.fcmToken!,
                data: {
                  type: 'round_ended',
                  roundId: args.roundId,
                  roundIndex: String(args.roundIndex),
                  endedReason: args.endedReason,
                  gameEnded: args.gameEnded ? 'true' : 'false',
                  title: localized.pushTitle,
                  body: localized.pushBody,
                },
              });
              if (
                result.errorCode === 'UNREGISTERED' ||
                result.errorCode === 'INVALID_ARGUMENT'
              ) {
                await ctx.runMutation(
                  internal.rooms.clearInvalidPushToken,
                  { playerId: t.playerId, field: 'pushTokenFcm' },
                );
              } else if (result.status >= 400) {
                console.error('[push] FCM error', result.status, result.errorCode);
              }
            } catch (err) {
              console.error('[push] FCM threw', err);
            }
          })(),
        );
      }
    }

    await Promise.allSettled(work);
  },
});
