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
    slug: 'newyork',
    category: 'city',
    sortOrder: 50,
    priceUsd: '$0.99',
    accentHex: '#F7B500',
    iconKey: 'location_city',
    translations: {
      en: {
        title: 'New York',
        tagline: 'Yellow cabs, bright lights, big rats.',
      },
      tr: {
        title: 'New York',
        tagline: 'Sarı taksiler, parlak ışıklar, koca fareler.',
      },
    },
  },
  {
    slug: 'london',
    category: 'city',
    sortOrder: 60,
    priceUsd: '$0.99',
    accentHex: '#C8102E',
    iconKey: 'directions_bus',
    translations: {
      en: {
        title: 'London',
        tagline: 'Fog, queues, and royal guards.',
      },
      tr: {
        title: 'Londra',
        tagline: 'Sis, kuyruklar ve kraliyet muhafızları.',
      },
    },
  },
  {
    slug: 'rome',
    category: 'city',
    sortOrder: 70,
    priceUsd: '$0.99',
    accentHex: '#C5A35A',
    iconKey: 'account_balance',
    translations: {
      en: {
        title: 'Rome',
        tagline: 'Ruins, gelato, and reckless Vespas.',
      },
      tr: {
        title: 'Roma',
        tagline: 'Harabeler, dondurma ve çılgın Vespalar.',
      },
    },
  },
  {
    slug: 'cairo',
    category: 'city',
    sortOrder: 80,
    priceUsd: '$0.99',
    accentHex: '#D4A017',
    iconKey: 'fort',
    translations: {
      en: {
        title: 'Cairo',
        tagline: 'Pyramids, bazaars, and the Nile breeze.',
      },
      tr: {
        title: 'Kahire',
        tagline: 'Piramitler, çarşılar ve Nil esintisi.',
      },
    },
  },
  {
    slug: 'rio',
    category: 'city',
    sortOrder: 90,
    priceUsd: '$0.99',
    accentHex: '#00A859',
    iconKey: 'sports_soccer',
    translations: {
      en: {
        title: 'Rio de Janeiro',
        tagline: 'Beaches, samba, and carnival chaos.',
      },
      tr: {
        title: 'Rio de Janeiro',
        tagline: 'Plajlar, samba ve karnaval keşmekeşi.',
      },
    },
  },
  {
    slug: 'berlin',
    category: 'city',
    sortOrder: 95,
    priceUsd: '$0.99',
    accentHex: '#FFCE00',
    iconKey: 'nightlife',
    translations: {
      en: {
        title: 'Berlin',
        tagline: 'Techno, currywurst, and cold history.',
      },
      tr: {
        title: 'Berlin',
        tagline: 'Tekno, currywurst ve soğuk tarih.',
      },
    },
  },
  {
    slug: 'dubai',
    category: 'city',
    sortOrder: 96,
    priceUsd: '$0.99',
    accentHex: '#C9A227',
    iconKey: 'apartment',
    translations: {
      en: {
        title: 'Dubai',
        tagline: 'Gold, skyscrapers, and desert heat.',
      },
      tr: {
        title: 'Dubai',
        tagline: 'Altın, gökdelenler ve çöl sıcağı.',
      },
    },
  },
  {
    slug: 'bangkok',
    category: 'city',
    sortOrder: 97,
    priceUsd: '$0.99',
    accentHex: '#FF6F61',
    iconKey: 'temple_buddhist',
    translations: {
      en: {
        title: 'Bangkok',
        tagline: 'Tuk-tuks, temples, and street woks.',
      },
      tr: {
        title: 'Bangkok',
        tagline: 'Tuk-tuklar, tapınaklar ve sokak wokları.',
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
  {
    slug: 'victorian1800s',
    category: 'theme',
    sortOrder: 110,
    priceUsd: '$0.99',
    accentHex: '#8C6A3F',
    iconKey: 'auto_stories',
    translations: {
      en: {
        title: 'Victorian London',
        tagline: 'Gaslight, fog, and proper scandal.',
      },
      tr: {
        title: 'Viktorya Dönemi',
        tagline: 'Gaz lambası, sis ve usulünce skandal.',
      },
    },
  },
  {
    slug: 'wildwest',
    category: 'theme',
    sortOrder: 120,
    priceUsd: '$0.99',
    accentHex: '#B5651D',
    iconKey: 'local_fire_department',
    translations: {
      en: {
        title: 'Wild West',
        tagline: 'Dust, six-shooters, and wanted posters.',
      },
      tr: {
        title: 'Vahşi Batı',
        tagline: 'Toz, altıpatlarlar ve aranıyor afişleri.',
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
 * One-shot migration. App Store / Play product IDs allow only
 * alphanumerics, periods, and underscores, and our entitlement IDs must
 * equal the slug — so the multi-word slugs were collapsed to a single
 * alphanumeric token (no separator). Renames the existing bundle rows and
 * repoints their locations' `bundleSlug`. Idempotent: a no-op once the old
 * slugs are gone (handles both the original hyphen and interim underscore
 * forms). Safe to delete after it has run in production.
 */
export const canonicalizeSlugs = mutation({
  args: {},
  handler: async (ctx) => {
    const RENAMES: Array<[string, string]> = [
      ['new-york', 'newyork'],
      ['new_york', 'newyork'],
      ['victorian-1800s', 'victorian1800s'],
      ['victorian_1800s', 'victorian1800s'],
      ['wild-west', 'wildwest'],
      ['wild_west', 'wildwest'],
    ];
    let bundles = 0;
    let locations = 0;
    for (const [from, to] of RENAMES) {
      const bundle = await ctx.db
        .query('bundles')
        .withIndex('by_slug', (q) => q.eq('slug', from))
        .first();
      if (bundle) {
        await ctx.db.patch(bundle._id, { slug: to });
        bundles++;
      }
      const locs = await ctx.db
        .query('locations')
        .withIndex('by_bundle', (q) => q.eq('bundleSlug', from))
        .collect();
      for (const l of locs) {
        await ctx.db.patch(l._id, { bundleSlug: to });
        locations++;
      }
    }
    return { bundles, locations };
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
 * locations with localized names and roles. `sampleRoles` (first 4) is
 * kept alongside the full `roles` list for backward compat with shipped
 * clients that only know the sample field.
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
        roles: localized.roles,
        totalRoles: localized.roles.length,
      };
    });

    return {
      ...project(bundle, args.locale),
      locationCount: locations.length,
      locations,
    };
  },
});
