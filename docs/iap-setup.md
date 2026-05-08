# In-App Purchase Setup Guide

End-to-end guide for configuring App Store Connect, Google Play Console, and RevenueCat so the marketplace inside the app can sell location bundles for real money on iOS and Android.

The Flutter side of this is already done in the repo — once the three dashboards below are configured and the build is run with the two RevenueCat SDK keys, purchases work end-to-end.

---

## 1. Product reference

Five **non-consumable** in-app purchases. One per location bundle. Same identifier on both stores.

| # | Bundle slug | Product ID (iOS + Android) | Type | Price | English title | Turkish title |
|---|---|---|---|---|---|---|
| 1 | `istanbul` | `com.walhallaa.spygame.v02202404.bundle.istanbul` | Non-consumable | **$0.99** USD | Istanbul Pack | İstanbul Paketi |
| 2 | `paris` | `com.walhallaa.spygame.v02202404.bundle.paris` | Non-consumable | **$0.99** USD | Paris Pack | Paris Paketi |
| 3 | `tokyo` | `com.walhallaa.spygame.v02202404.bundle.tokyo` | Non-consumable | **$0.99** USD | Tokyo Pack | Tokyo Paketi |
| 4 | `stockholm` | `com.walhallaa.spygame.v02202404.bundle.stockholm` | Non-consumable | **$0.99** USD | Stockholm Pack | Stockholm Paketi |
| 5 | `cyberpunk` | `com.walhallaa.spygame.v02202404.bundle.cyberpunk` | Non-consumable | **$0.99** USD | Cyberpunk Pack | Cyberpunk Paketi |

### Why non-consumable

- **Non-consumable** = a permanent, one-time unlock. The user owns it forever. Restorable to any device signed into the same store account. ✅ This is what we want.
- *Consumable* = something that gets "used up" (like in-game coins). Not restorable. Wrong fit.
- *Auto-renewable subscription* = recurring payment. Wrong fit.
- *Non-renewing subscription* = time-limited, no auto-renew. Wrong fit.

### Why same product ID on both stores

Google Play product IDs accept lowercase letters, digits, underscores, and **dots**. So we can use the iOS-style reverse-DNS ID on both stores. This makes RevenueCat's cross-store mapping trivial — one identifier per pair.

### Localized copy (use this for both stores)

For each bundle, both stores ask for a **display name** and **description** per supported language. The display names and descriptions below match the in-app catalog (`convex/bundles.ts`).

**Istanbul**
- EN name: `Istanbul Pack`
- EN description: `Bazaars, ferries, and stray cats. 6 new locations and 66 roles for your games.`
- TR name: `İstanbul Paketi`
- TR description: `Pazarlar, vapurlar ve sokak kedileri. Oyunların için 6 yeni mekân ve 66 rol.`

**Paris**
- EN name: `Paris Pack`
- EN description: `Cafés, métro, and museum heists. New locations and roles for your games.`
- TR name: `Paris Paketi`
- TR description: `Kafeler, metro ve müze soygunları. Oyunların için yeni mekânlar ve roller.`

**Tokyo**
- EN name: `Tokyo Pack`
- EN description: `Karaoke, capsule hotels, and code. New locations and roles for your games.`
- TR name: `Tokyo Paketi`
- TR description: `Karaoke, kapsül oteller ve kod. Oyunların için yeni mekânlar ve roller.`

**Stockholm**
- EN name: `Stockholm Pack`
- EN description: `Saunas, Vasa, and herring. New locations and roles for your games.`
- TR name: `Stockholm Paketi`
- TR description: `Saunalar, Vasa ve ringa balığı. Oyunların için yeni mekânlar ve roller.`

**Cyberpunk**
- EN name: `Cyberpunk Pack`
- EN description: `Neon, chrome, and bad decisions. New locations and roles for your games.`
- TR name: `Cyberpunk Paketi`
- TR description: `Neon, krom ve kötü kararlar. Oyunların için yeni mekânlar ve roller.`

> Update the location/role counts after running `npx convex run bundles:list` if you want exact numbers per bundle.

---

## 2. App Store Connect setup

### Prerequisites

1. **Active Apple Developer Program account** ($99/yr). The app `com.walhallaa.spygame.v02202404` is already registered.
2. **Paid Apps Agreement signed** under *Agreements, Tax, and Banking*. **This is the most-missed step** — without it, IAPs return errors and never appear in sandbox.
3. **Banking + tax forms completed** for the territories you'll sell in. Without these, products stay in "Developer Action Needed" state.

### A. Enable In-App Purchase capability in Xcode

The capability must be enabled on the Runner target so the App Store will accept builds.

1. Open `ios/Runner.xcworkspace` in Xcode (use the workspace, not the project).
2. Click the **Runner** project in the navigator → select the **Runner** target.
3. Go to **Signing & Capabilities** tab.
4. Click **+ Capability** → search **In-App Purchase** → double-click to add.
5. Commit the changes to `ios/Runner.xcodeproj/project.pbxproj`.

### B. Create the 5 IAPs in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → your app.
2. Sidebar: **Monetization** → **In-App Purchases**. (On older accounts this lives under *Features*.)
3. Click **+ Create**.
4. Choose type **Non-Consumable**.
5. Fill in:
   - **Reference Name**: `Istanbul Pack` (internal label, never shown to users)
   - **Product ID**: `com.walhallaa.spygame.v02202404.bundle.istanbul` ⚠️ **A product ID can never be reused — typos here are permanent.**
6. Save → you're now on the product detail page. Fill the rest:
   - **Availability**: All countries/regions (or restrict as needed).
   - **Price Schedule**: Tier 1 ($0.99 USD). Apple auto-converts to other currencies.
   - **App Store Localization**:
     - Click **+** to add **English (U.S.)** → paste the EN name + description from §1.
     - Click **+** to add **Turkish** → paste the TR name + description.
   - **Review Information**:
     - **Screenshot**: 1024×1024 PNG showing the bundle inside the marketplace screen of the app. Take it on a real device or simulator. The reviewer needs to see what the user is buying.
     - **Review Notes**: `Non-consumable location pack for the Spyfall-style party game. Unlocks 6 additional venues for round play. Tap any locked bundle in the Marketplace to see this product.`
7. Click **Save** → product status becomes **Ready to Submit**.
8. **Repeat steps 3–7 for the other 4 bundles** (Paris, Tokyo, Stockholm, Cyberpunk). Use the matching product IDs from §1.

> **Submitting for review**: products are submitted *with* the next app build. They don't need to be reviewed standalone. Once you upload a build to TestFlight that references these IAPs, they get queued for review. The first IAP per app may take 24–48h.

### C. Generate the App Store Connect API key (for RevenueCat)

RevenueCat uses this key to read receipts and listen for refunds.

1. App Store Connect → click your name top-right → **Users and Access** → **Integrations** tab → **App Store Connect API**.
2. **Generate API Key** (the *In-App Purchase* role is sufficient; *Admin* also works).
3. Note the **Issuer ID** (shown at the top of the page — same for all keys in this account).
4. Note the **Key ID** of the new key.
5. **Download the .p8 file**. ⚠️ **You can only download it once.** Save it somewhere safe (1Password, etc.).

You'll paste these three values (Issuer ID, Key ID, .p8 contents) into RevenueCat in §4.

### D. Create sandbox tester accounts (for testing)

1. App Store Connect → **Users and Access** → **Sandbox** tab → **Testers** → **+**.
2. Create one tester per device / per locale you want to test.
3. Use a **brand-new email that's never been used with any Apple ID** — Apple is strict about this. A `+sandbox` alias works (e.g. `you+sandbox-tr@gmail.com`).
4. Pick a region that matches the locale you want to test pricing in.
5. On the iPhone you're testing with: **Settings → Developer → Sandbox Apple Account** (iOS 14+). Sign in there. *Don't* sign in via the regular App Store settings.

---

## 3. Google Play Console setup

### Prerequisites

1. **Active Google Play Developer account** ($25 one-time fee).
2. The app `com.walhallaa.spygame.v02202404` must already be created in Play Console with at least one build uploaded to **Internal testing** track. Play won't let you create IAPs for an app that has no track / no APK.
3. **Payments profile linked** under *Setup → Payments profile* (Merchant Center). Without this, IAPs can be created but can never collect money.

### A. Create the 5 IAPs in Play Console

1. Go to [Google Play Console](https://play.google.com/console) → your app.
2. Sidebar: **Monetize → Products → In-app products**.
3. Click **Create product**.
4. Fill in:
   - **Product ID**: `com.walhallaa.spygame.v02202404.bundle.istanbul` ⚠️ **Permanent — cannot be reused after deletion.**
   - **Name**: `Istanbul Pack`
   - **Description**: paste the EN description from §1.
   - **Price**: $0.99 USD. Click **Set prices** and apply Google's auto-conversion to all other currencies (or pick a "pricing template" if you create one).
5. Click **Save** → product is **Inactive** by default.
6. Click **Activate** to make it purchasable.
7. (Optional but recommended) Add Turkish translations: click the product → **Translations** → **Manage translations** → add Turkish → paste the TR name and description.
8. **Repeat for the other 4 bundles.**

### B. Service account for RevenueCat

RevenueCat uses a Google service account to read purchases, validate receipts, and listen for voided/refunded orders.

#### B.1 — Create the service account in Google Cloud

1. [Google Cloud Console](https://console.cloud.google.com) → top selector → pick the project linked to your Play account (Play creates one automatically; it's named like `pc-api-...` or similar — check Play Console → Setup → API access to find which project is linked).
2. **IAM & Admin → Service Accounts → + Create Service Account**.
3. Name: `revenuecat-server`. Description: `Read-only access for RevenueCat to validate receipts.`
4. Skip the optional roles step (we'll grant Play permissions in B.3).
5. After creation, click the service account → **Keys → Add Key → Create new key → JSON → Create**. A `.json` file downloads. Save it. ⚠️ Apparently can only download once.

#### B.2 — Enable the Google Play Android Developer API

1. Same Google Cloud project → **APIs & Services → Library**.
2. Search **Google Play Android Developer API** → **Enable**.

#### B.3 — Grant the service account access in Play Console

1. Play Console → **Setup → API access**.
2. The service account should appear here automatically (linked via the Cloud project). If not, click **Link new** and select the project.
3. Find the `revenuecat-server@…` service account → **Grant access**.
4. Permissions tab: enable
   - **View financial data, orders, and cancellation survey responses**
   - **Manage orders and subscriptions**
5. **Apply** → **Send invite**.

You'll upload the `.json` file from B.1 into RevenueCat in §4.

### C. Add license testers (for testing)

License testers can buy your IAPs without being charged.

1. Play Console → **Setup → License testing**.
2. Add the Google account email of each tester device.
3. Set **License response** to `RESPOND_NORMALLY`.
4. **Save changes**.

### D. Internal testing track

You need to upload a signed build with the products referenced (i.e. with the RC SDK keys baked in) before products can be queried.

1. Build a release APK or AAB with the dart-define keys (see §5).
2. Play Console → **Testing → Internal testing → Create new release**.
3. Upload the AAB → review → **Save** → **Review release** → **Start rollout**.
4. Add yourself + license testers to the **Testers** list.
5. Use the **Copy link** button on the testers page to install via Play Store on a tester device.

> First Play upload of a new app takes 1–2 hours to propagate to internal testing. Subsequent uploads take ~10 minutes.

---

## 4. RevenueCat setup

### Concepts (read this once)

RevenueCat layers four nouns on top of store products:

- **Product** = a thing that exists in App Store Connect or Play Console. Has a price. There are typically two products per bundle (one per store), grouped together.
- **Entitlement** = the *capability* a user has after purchasing. Maps the slug we use in the app (`istanbul`) to the products that grant it.
- **Package** = a way to present a product in the app. Each package wraps one iOS product + one Android product so the app code is platform-agnostic.
- **Offering** = a set of packages shown together in the storefront. We use one default offering containing all 5 packages.

The Flutter code reads `Offering.availablePackages` → finds the package whose `identifier == bundleSlug` → calls `Purchases.purchase(...)`. RC then swaps to the correct iOS or Android product based on the device.

### A. Create the project and apps

1. Sign in / sign up at [app.revenuecat.com](https://app.revenuecat.com).
2. **+ New project**: name `SpyGame`. Click **Create**.
3. **Project Settings → Apps → + Add app**.
4. **App Store** app:
   - Name: `SpyGame iOS`
   - **App Bundle ID**: `com.walhallaa.spygame.v02202404`
   - **App Store Connect App-Specific Shared Secret**: leave blank (Apple deprecated this; the API key replaces it).
   - **App Store Connect API Key**: paste the **Issuer ID**, **Key ID**, and the **contents of the .p8 file** from §2C.
   - Save.
5. Back to **Apps → + Add app → Play Store**.
   - Name: `SpyGame Android`
   - **Package Name**: `com.walhallaa.spygame.v02202404`
   - **Service Account Credentials**: upload the JSON file from §3B.1.
   - Save.
6. **Project Settings → API keys**: copy the two **Public SDK keys**:
   - `appl_...` (iOS) — paste this as `REVENUECAT_IOS_KEY` in §5.
   - `goog_...` (Android) — paste this as `REVENUECAT_ANDROID_KEY` in §5.

> The "secret" API keys also visible on this page are for server-side use only. **Never** ship them in the app. The `appl_` and `goog_` keys are the only ones the Flutter app needs.

### B. Import products

1. **Product catalog → Products → + New** → **Import products**.
2. Pull from **App Store Connect** — RC will detect all 5 IAPs you created. Tick all 5 → Import.
3. Pull from **Play Store** — same, tick all 5 → Import.

You should now have 10 products listed (5 per store), with matching IDs.

### C. Create entitlements

One entitlement per bundle. Entitlement IDs **must equal** the bundle slugs because the Flutter code looks them up by name.

1. **Product catalog → Entitlements → + New entitlement**.
2. ID: `istanbul`. Display name: `Istanbul Pack`. Save.
3. Click into the `istanbul` entitlement → **Attach products** → tick:
   - `com.walhallaa.spygame.v02202404.bundle.istanbul` (App Store)
   - `com.walhallaa.spygame.v02202404.bundle.istanbul` (Play Store)
   - Save.
4. **Repeat for the 4 other entitlements**: `paris`, `tokyo`, `stockholm`, `cyberpunk`. Each gets its iOS+Android product pair attached.

### D. Create the offering and packages

1. **Product catalog → Offerings → + New offering**.
2. Identifier: `default`. Display name: `Default`. Save.
3. Click into the `default` offering → **+ Add package**.
4. For each bundle, create one package:
   - **Identifier**: `istanbul` (custom — must equal the slug; the Flutter code looks it up by `Package.identifier`)
   - **Display name**: `Istanbul Pack`
   - **Package type**: Custom
   - **Products**: attach the iOS + Android products for `istanbul`.
   - Save.
5. Repeat for `paris`, `tokyo`, `stockholm`, `cyberpunk`.
6. Back on the offerings list, click the **⋯** on `default` → **Make current**. The "current" offering is what the SDK returns from `getOfferings().current`.

### E. (Optional) Disable RevenueCat's web paywall preview

RevenueCat sends a "first-paywall" prompt by default. Since we render our own UI, you can ignore it. No action needed.

---

## 5. Flutter build configuration

### A. Put the keys in `.env.local`

Open `.env.local` (already gitignored) and fill the two empty placeholders:

```
REVENUECAT_IOS_KEY=appl_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
REVENUECAT_ANDROID_KEY=goog_xxxxxxxxxxxxxxxxxxxxxxxxx
```

### B. Local dev: `./run.sh`

`run.sh` is a thin wrapper around `flutter run` that auto-loads the keys from `.env.local` and forwards any extra args:

```bash
./run.sh                    # default device
./run.sh -d "iPhone 16"     # specific simulator
./run.sh -d chrome          # web (browse-only, RC unsupported)
./run.sh --release          # release-mode local run
```

Under the hood it runs:
```bash
flutter run \
  --dart-define=REVENUECAT_IOS_KEY=$REVENUECAT_IOS_KEY \
  --dart-define=REVENUECAT_ANDROID_KEY=$REVENUECAT_ANDROID_KEY \
  "$@"
```

### C. Release builds: `./deploy.sh`

`deploy.sh` already sources `.env.local` at startup, so the iOS build now picks up the RC keys automatically — no extra flags needed:

```bash
./deploy.sh                 # full ship: Convex deploy + iOS build + ASC upload + web + git
./deploy.sh --no-upload     # archive + export the IPA only, skip ASC upload
./deploy.sh --dry           # full path, zero side effects (good for testing)
```

> Public SDK keys are safe to ship in client builds — that's what they're designed for. Don't confuse them with the `sk_` secret keys, which must never appear in client code.

### D. CI / external build systems

If you build outside of `deploy.sh` / `run.sh` (e.g. Codemagic, GitHub Actions, Xcode Cloud), add the two values as encrypted environment variables and pass them through manually:

```yaml
# example: GitHub Actions
- run: |
    flutter build appbundle \
      --dart-define=REVENUECAT_IOS_KEY=$REVENUECAT_IOS_KEY \
      --dart-define=REVENUECAT_ANDROID_KEY=$REVENUECAT_ANDROID_KEY
  env:
    REVENUECAT_IOS_KEY: ${{ secrets.REVENUECAT_IOS_KEY }}
    REVENUECAT_ANDROID_KEY: ${{ secrets.REVENUECAT_ANDROID_KEY }}
```

### E. Behavior without keys

If either key is missing or empty, the app boots fine but `RevenueCatBootstrap.initialize()` skips configuration and logs a debug warning. The marketplace falls back to **browse-only mode** (no Buy / Restore controls). This is the same fallback used on Flutter Web (where `purchases_flutter` is not supported). `run.sh` also prints a one-line notice so you don't waste time wondering why purchases aren't working.

---

## 6. Testing checklist

### iOS sandbox

Run on a **real device** signed into a sandbox Apple account (Settings → Developer → Sandbox Apple Account). Simulator does not support StoreKit purchases for sandbox accounts.

- [ ] App launches with the keys passed via `--dart-define`.
- [ ] Open Marketplace → bundle cards show **localized RC prices** (e.g. `$0.99` or `₺X` depending on sandbox account region) instead of the Convex fallback `$0.99`.
- [ ] Tap a locked bundle → detail screen → tap **UNLOCK · $0.99** → sandbox auth prompt → success.
- [ ] After purchase, the bundle card immediately switches to **OWNED** (lime border, check icon).
- [ ] Start a game as host → confirm locations from the unlocked bundle now appear in the venue pool (open the locations sheet).
- [ ] Delete app → reinstall (clientToken regenerates) → tap **Restore purchases** in the marketplace header → the bundle returns to OWNED.
- [ ] Trigger a sandbox refund (App Store Connect → Sandbox Tester → revoke the purchase) → with the app open, the bundle reverts to locked within ~30s (RC's `CustomerInfoUpdateListener` fires).

### Android internal testing

Install the build via the Internal testing Play Store link on a license-tester device.

- [ ] Open Marketplace → prices appear localized (license testers see "This is a test purchase" but $0.00 charged).
- [ ] Tap **UNLOCK** → sandbox auth → success.
- [ ] Reinstall → **Restore purchases** → bundle returns.
- [ ] Refund via Play Console → bundle reverts to locked.

### Web

- [ ] `./run.sh -d chrome` → Marketplace renders, **Buy** and **Restore** buttons replaced by the inline hint *"Purchases available on iOS and Android."* No console errors from `purchases_flutter`.

### Offline tolerance

- [ ] Buy a bundle online, then enable airplane mode → close & reopen app → marketplace still shows the bundle as OWNED (RC caches `CustomerInfo` for ~5 minutes).

---

## 7. Common gotchas

### App Store

- **"Cannot connect to iTunes Store"** in sandbox → you're signed into a real Apple ID, not the sandbox one. Re-check **Settings → Developer → Sandbox Apple Account**.
- **Products return empty in `getOfferings()`** → the IAP isn't approved/active *and* attached to a bundle in App Store Connect. New IAPs sit in "Ready to Submit" until you upload a build referencing them via TestFlight; the first build can take ~24h to propagate. Sometimes shipping a build to TestFlight is what unblocks the offering, even before App Review.
- **"Missing tax / banking info"** banner → IAPs literally do not work until *Agreements, Tax, and Banking* shows all green checks.

### Google Play

- **Products say "(unavailable)"** in the app → the build you're testing isn't from Play (e.g. you side-loaded an APK). Play Billing only returns products for builds installed via the Play Store, even on internal track.
- **"This version of the app isn't configured for billing"** → you uploaded a debug build that wasn't signed with the upload key. Use a release build via the Internal testing track.
- **License tester sees a real charge** → email isn't in *Setup → License testing*. Add it and reinstall.

### RevenueCat

- **`[Purchases]` log says "configured but no app user ID"** → bootstrap ran before `IdentityStorage.init()`. Confirm the order in `lib/main.dart`.
- **`getOfferings().current` returns `null`** → the offering isn't marked as **Current** in the dashboard. Project Settings → Offerings → ⋯ → **Make current**.
- **"Receipt validation error" in webhook logs** → service account permissions in Play Console are too narrow. Re-grant *View financial data* AND *Manage orders and subscriptions*.
- **iOS sandbox purchases stick around forever** → that's expected. To "reset" a sandbox tester, sign out and back in via Settings → Developer → Sandbox Apple Account, or create a new tester.

### Flutter / build

- **iOS build error after adding `purchases_flutter`** → run `cd ios && pod install --repo-update`. CocoaPods sometimes has stale spec repos.
- **Android build error: "Manifest merger failed"** → almost always a `minSdk` issue. RC requires Android API 21+; `flutter.minSdkVersion` already meets this. If you bumped your `minSdk`, ensure it's ≥ 21.

---

## 8. Quick post-setup verification

After completing all 4 sections, this two-minute sanity check confirms everything is wired:

1. On an iOS device with sandbox account active, fill the keys in `.env.local` and run:
   ```bash
   ./run.sh
   ```
2. Open marketplace → tap any locked bundle → see RC's localized price string (not the Convex fallback).
3. RevenueCat dashboard → **Customers** → you should see a new customer record with the App User ID equal to your device's `clientToken` (a UUID v4).
4. Tap UNLOCK → complete sandbox purchase → the customer record now shows the matching entitlement as **active**.

If all four steps work, you're shipping-ready. Cut a real release build with the production keys and submit to TestFlight / Internal testing.
