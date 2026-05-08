import { ConvexError, v } from 'convex/values';

import { Doc } from './_generated/dataModel';
import { mutation, query } from './_generated/server';

/**
 * Static catalog of paid location packs. Server is the source of truth
 * for which slugs exist and which locations belong to each. Ownership is
 * driven on-device by RevenueCat — the platform store receipt (Apple /
 * Google) is the cryptographic proof of purchase, so the server does
 * not need to validate ownership claims and there are no user records.
 * `priceUsd` here is a display fallback only; the live UI prefers RC's
 * locale-formatted `priceString` from the active offering.
 */
type SeedBundle = {
  slug: string;
  category: 'city' | 'theme';
  sortOrder: number;
  priceUsd: string;
  accentHex: string;
  iconKey: string;
  translations: {
    en: { title: string; tagline: string };
    tr: { title: string; tagline: string };
  };
};

const LOCALE_VALIDATOR = v.optional(v.union(v.literal('en'), v.literal('tr')));
type Locale = 'en' | 'tr';

const SEED: SeedBundle[] = [
  {
    slug: 'istanbul',
    category: 'city',
    sortOrder: 10,
    priceUsd: '$0.99',
    accentHex: '#E4572E',
    iconKey: 'mosque',
    translations: {
      en: {
        title: 'Istanbul',
        tagline: 'Bazaars, ferries, and stray cats.',
      },
      tr: {
        title: 'İstanbul',
        tagline: 'Pazarlar, vapurlar ve sokak kedileri.',
      },
    },
  },
  {
    slug: 'paris',
    category: 'city',
    sortOrder: 20,
    priceUsd: '$0.99',
    accentHex: '#4CC9F0',
    iconKey: 'local_cafe',
    translations: {
      en: {
        title: 'Paris',
        tagline: 'Cafés, métro, and museum heists.',
      },
      tr: {
        title: 'Paris',
        tagline: 'Kafeler, metro ve müze soygunları.',
      },
    },
  },
  {
    slug: 'tokyo',
    category: 'city',
    sortOrder: 30,
    priceUsd: '$0.99',
    accentHex: '#F15BB5',
    iconKey: 'ramen_dining',
    translations: {
      en: {
        title: 'Tokyo',
        tagline: 'Karaoke, capsule hotels, and code.',
      },
      tr: {
        title: 'Tokyo',
        tagline: 'Karaoke, kapsül oteller ve kod.',
      },
    },
  },
  {
    slug: 'stockholm',
    category: 'city',
    sortOrder: 40,
    priceUsd: '$0.99',
    accentHex: '#00B4D8',
    iconKey: 'sailing',
    translations: {
      en: {
        title: 'Stockholm',
        tagline: 'Saunas, Vasa, and herring.',
      },
      tr: {
        title: 'Stockholm',
        tagline: 'Saunalar, Vasa ve ringa balığı.',
      },
    },
  },
  {
    slug: 'cyberpunk',
    category: 'theme',
    sortOrder: 100,
    priceUsd: '$0.99',
    accentHex: '#9B5DE5',
    iconKey: 'electric_bolt',
    translations: {
      en: {
        title: 'Cyberpunk',
        tagline: 'Neon, chrome, and bad decisions.',
      },
      tr: {
        title: 'Cyberpunk',
        tagline: 'Neon, krom ve kötü kararlar.',
      },
    },
  },
];

function project(b: Doc<'bundles'>, locale: Locale | undefined) {
  const t = locale === 'tr' ? b.translations.tr : b.translations.en;
  return {
    slug: b.slug,
    category: b.category,
    sortOrder: b.sortOrder,
    priceUsd: b.priceUsd,
    accentHex: b.accentHex,
    iconKey: b.iconKey,
    title: t.title,
    tagline: t.tagline,
  };
}

/**
 * Idempotent: inserts SEED rows that don't already exist by slug. Patches
 * mutable display fields (price, accent, icon, translations) on rows
 * that do exist so editing the seed table here is enough to update
 * production. Slug + category never change.
 */
export const seed = mutation({
  args: {},
  handler: async (ctx) => {
    let inserted = 0;
    let patched = 0;
    const all = await ctx.db.query('bundles').collect();
    const bySlug = new Map(all.map((b) => [b.slug, b]));
    for (const s of SEED) {
      const existing = bySlug.get(s.slug);
      if (!existing) {
        await ctx.db.insert('bundles', s);
        inserted++;
        continue;
      }
      const patch: Record<string, unknown> = {};
      if (existing.priceUsd !== s.priceUsd) patch.priceUsd = s.priceUsd;
      if (existing.accentHex !== s.accentHex) patch.accentHex = s.accentHex;
      if (existing.iconKey !== s.iconKey) patch.iconKey = s.iconKey;
      if (existing.sortOrder !== s.sortOrder) patch.sortOrder = s.sortOrder;
      if (
        existing.translations.en.title !== s.translations.en.title ||
        existing.translations.en.tagline !== s.translations.en.tagline ||
        existing.translations.tr.title !== s.translations.tr.title ||
        existing.translations.tr.tagline !== s.translations.tr.tagline
      ) {
        patch.translations = s.translations;
      }
      if (Object.keys(patch).length > 0) {
        await ctx.db.patch(existing._id, patch);
        patched++;
      }
    }
    return { inserted, patched };
  },
});

/**
 * Marketplace listing. Returns each bundle plus its location count so
 * the storefront card can show "6 locations" without a second round-trip.
 */
export const list = query({
  args: { locale: LOCALE_VALIDATOR },
  handler: async (ctx, args) => {
    const bundles = await ctx.db.query('bundles').collect();
    const result: Array<ReturnType<typeof project> & { locationCount: number }> = [];
    for (const b of bundles) {
      const locs = await ctx.db
        .query('locations')
        .withIndex('by_bundle', (q) => q.eq('bundleSlug', b.slug))
        .collect();
      result.push({ ...project(b, args.locale), locationCount: locs.length });
    }
    result.sort((a, b) => a.sortOrder - b.sortOrder);
    return result;
  },
});

/**
 * Bundle detail view. Returns the bundle metadata plus the list of
 * locations with localized names and a few sample roles. Does NOT expose
 * the full role list — sample is enough for the marketplace preview and
 * keeps the response small.
 */
export const detail = query({
  args: { slug: v.string(), locale: LOCALE_VALIDATOR },
  handler: async (ctx, args) => {
    const bundle = await ctx.db
      .query('bundles')
      .withIndex('by_slug', (q) => q.eq('slug', args.slug))
      .first();
    if (!bundle) throw new ConvexError(`Bundle not found: ${args.slug}`);

    const locs = await ctx.db
      .query('locations')
      .withIndex('by_bundle', (q) => q.eq('bundleSlug', args.slug))
      .collect();

    const locations = locs.map((l) => {
      const localized =
        args.locale === 'tr' && l.translations?.tr
          ? { name: l.translations.tr.name, roles: l.translations.tr.roles }
          : { name: l.name, roles: l.roles };
      return {
        _id: l._id,
        name: localized.name,
        sampleRoles: localized.roles.slice(0, 4),
        totalRoles: localized.roles.length,
      };
    });

    return {
      ...project(bundle, args.locale),
      locations,
    };
  },
});
