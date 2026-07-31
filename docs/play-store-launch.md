# Google Play launch — manual steps

Everything that can't be done from the terminal, in the order you'll hit it.
Companion to `docs/app-store-listing.md` (listing copy) and `docs/iap-setup.md`
(in-app purchases, which already has a full Play + RevenueCat section).

> **Nothing here needs a Play CLI.** The keystore is generated offline by
> `keytool`, and Google Play refuses the *first* upload of a new app over its
> API — that one has to go through the web console by hand. Automation only
> becomes possible from the second upload onward (§8).

---

## 0. Already done for you

| Thing | Where |
|---|---|
| Upload keystore generated | `/Users/muratcankoc/keystores/spygame_upload.jks` |
| Signing credentials | `android/key.properties` (gitignored) |
| Release signing wired into Gradle | `android/app/build.gradle.kts` |
| Build script that injects RevenueCat keys | `./build_android.sh` |
| First signed bundle built | `build/app/outputs/bundle/release/app-release.aab` (86 MB) |

The 86 MB is the *bundle*, not the download. Play splits it per device
architecture and language, so the actual install is roughly a quarter of that.

### Keystore fingerprints

Firebase and some Google services ask for these:

```
SHA1:   A5:45:8A:F8:11:FE:25:7C:40:14:4B:B4:DB:6D:8A:40:74:4A:AF:BA
SHA256: 62:A8:F5:5E:21:2A:1E:7A:A0:2C:AE:65:98:E2:62:CF:1D:74:9D:F2:5D:40:F3:B6:24:D0:EB:51:C6:40:86:6D
```

Note these are the **upload key** fingerprints. Once Play App Signing is
active, Play re-signs your app with a *different* key it holds. Anything that
verifies the installed app (deep-link asset links, Google Sign-In) must use the
**app signing key** fingerprint from *Play Console → Test and release → Setup →
App integrity*, not the ones above.

### ⚠️ Back this up now

`spygame_upload.jks` sits **outside** the repo and is in no backup you control
automatically. Put the `.jks` file and the password from `android/key.properties`
into your password manager today. This keystore is separate from
`swirlyourwines_upload.jks` and `monkeyhub_upload.jks` — different app,
different developer account, do not mix them up.

If you ever do lose it: because you accepted Play App Signing, Google holds the
real signing key and you can request an upload-key reset. Annoying, not fatal.

---

## 1. Create the app (the screen you're on)

| Field | Value |
|---|---|
| App name | `Where am I? - Spy Game` |
| Package name | `com.walhallaa.spygame.v02202404` |
| Default language | English (United States) |
| App or game | **Game** |
| Free or paid | **Free** |
| Declarations | Tick all three |

**Package name is permanent.** It matches `applicationId` in
`android/app/build.gradle.kts:36` and the iOS bundle ID. **Free is effectively
permanent too** — a published free app can never become paid. Correct here: the
revenue comes from the 5 location packs as in-app purchases.

---

## 2. Store listing

Copy from `docs/app-store-listing.md`, which already has both English and
Turkish text within Play's limits.

| Field | Limit | Source |
|---|---|---|
| App name | 30 | `Where am I? - Spy Game` |
| Short description | 80 | listing doc line 270 |
| Full description | 4000 | listing doc, App Store description section |

Add Turkish as a second language (**Store listing → Manage translations**) —
the app already ships Turkish localisation, and the TR copy is in the listing doc.

### Graphics you must create

| Asset | Spec | Required |
|---|---|---|
| App icon | 512×512 PNG, 32-bit, no transparency | Yes |
| Feature graphic | 1024×500 PNG/JPG | Yes |
| Phone screenshots | 2–8, min 320px, max 3840px, 16:9 or 9:16 | Yes (min 2) |
| 7-inch tablet | 1–8 | No |
| 10-inch tablet | 1–8 | No |

The feature graphic is the banner across the top of your store page. It is
mandatory and has no App Store equivalent, so it likely doesn't exist yet.
You can reuse the iOS App Store screenshots if their aspect ratio fits.

---

## 3. Required policy forms

Play blocks publishing until every one of these is green. Left menu →
**Policy and programmes → App content**.

### Privacy policy
URL: `https://walhallaa.com/whereami-privacy-terms` (already used for iOS —
**verify it loads** before submitting; a dead link is an instant rejection).

### App access
The app has no login, no accounts, no gated content. Select
**All functionality is available without special access**.

### Ads
**No, my app does not contain ads.**

### Content rating
A questionnaire (category: Game). Answers below were derived by scanning all
2,550 role strings in `convex/locations.ts` plus `convex/schema.ts` — not
guessed. Re-check them whenever a new location pack ships.

**The rule that decides every borderline case:** only answer Yes when at least
one sub-option is *truthfully tickable*. Several top-level questions say
"references to", which text alone satisfies — but their sub-forms then demand
you specify **depictions** (which body parts are shown, what gore is rendered).
For a text-only game those are all false, so Yes would force a false
declaration. That asymmetry is what settles violence and nudity as No.

| Question | Answer | Sub-form | Evidence |
|---|---|---|---|
| Violence, blood, gore | No | — | `Gunsmith`, `Hired Gun`, `Shotgun Guard` are job titles; sub-form asks for depictions of blood/gore, all false |
| Fear | No | — | Question is scoped to "pictures or sounds"; game has neither |
| Sexuality / suggestiveness | **Yes** | tick only `Suggestive/Sexual Themes or References` | `Naked Sauna Regular`, `Bikini Seller`, `Honeymoon Couple`. NOT `Nudity or Revealing Outfits` — that branch demands depicted body parts |
| Gambling | **Yes** | tick only `Gambling themes`; strong focus → **No** | `Casino Floor`, `Underground Casino`, `Race Track` + `Croupier`, `Bookie` — 3 of ~174 locations, no playable mechanic |
| Language | No | — | No profanity across 2,550 roles |
| Controlled substance | **Yes** | tick `Alcohol` + `Tobacco` only | `Bartender`, `Brewmaster`, `Whiskey Trader`, `Sommelier` / `Cigar Girl`, `Hookah Master`, `Nargileci`. NOT illegal/fantasy drugs (none — `Shady Dealer` sells antiques). NOT medical drugs (`Pharmacist`, `Anesthesiologist` are occupations, no depicted use) |
| Crude humor | No | — | Only `Person Looking for the Toilet` |
| Digital purchases | **Yes** | tick `Purchases of digital goods` only | 5 location packs. The sub-form gives NFTs and cash-convertible rewards their own separate boxes — leave both empty. Ordinary IAP is caught by the first box |
| Users interact / exchange content | No | — | No chat table in the schema; only `displayName` (`schema.ts:55`) |
| Shares precise location | No | — | No location permission; game "locations" are fictional |
| Nazi / Korea / terrorism | No | — | — |
| Realistic crime descriptions | No | — | `Pickpocket`, `Masked Robber`, `Smuggler` are one-word occupation labels, not descriptions or techniques |

### Ratings actually issued (2026-07-31)

Declared: gambling themes; alcohol reference (rarely); tobacco reference
(rarely); purchases of digital goods. Sexuality was submitted as **No** — the
sub-form would not advance on `Suggestive Themes` alone, and the remaining
boxes (sexual activity imagery, sexual violence) are categorically false.

| Region | Rating |
|---|---|
| Europe (PEGI) | **PEGI 3** |
| Germany (USK) | **All ages** |
| North America (ESRB) | **Everyone** — Alcohol and Tobacco Reference |
| Rest of world / Russia | 3+ |
| Australia | Parental Guidance |
| Brazil | 14+ |
| Taiwan | PG 15 |
| South Korea | 15+ |
| Saudi Arabia | 16 |

The teen gates in Korea/Taiwan/Brazil/Saudi are mechanical consequences of any
alcohol-tobacco or gambling declaration in those territories — not appealable
and not a sign of a wrong answer.

> If a future pack adds explicit content, amend the questionnaire rather than
> leaving it stale — IARC re-rates after review and enforcement follows
> misrepresentation, not honest updates.

> **If you ever add in-app chat, you must update the "users interact" answer.**
> Under-declaring user interaction is a known enforcement trigger.

### Target audience and content
Pick your age groups. **Avoid ticking any band under 13** unless you truly
intend to target children — it pulls you into the Families Policy, which adds
extra requirements around ads SDKs, data collection and a separate review.

### Data safety
This is the fiddly one. Based on what the app actually does:

| Question | Answer |
|---|---|
| Does your app collect or share user data? | **Yes** |
| Is data encrypted in transit? | **Yes** (HTTPS to Convex) |
| Can users request data deletion? | Rooms auto-purge; describe the cron cleanup |

Data types to declare:
- **Player name** → collected, not shared, optional, app functionality
- **Device / push token** (FCM) → collected, not shared, app functionality
- **Purchase history** (via RevenueCat) → collected, app functionality
- **App interactions / crash logs** → only if you actually collect them

There is no auth, no email, no location, no contacts, no analytics identity —
say so, and don't over-declare. Over-declaring makes your store page look
worse than reality.

### Government apps / financial features / health
All **No**.

---

## 4. ⚠️ Check the testing requirement before promising a launch date

If your Play developer account is a **personal/individual** account (not a
registered company), Google requires a period of **closed testing with a
minimum number of real testers, sustained over a continuous window**, before
you can even apply for production access.

Go to **Test and release → Testing → Closed testing** and read the exact
tester count and duration your console shows — it's account-specific and Google
changes the numbers. This is the single biggest surprise for first-time
publishers and can add weeks to a launch.

Plan the track order: **Internal testing** (instant, up to 100 testers, use this
to verify IAP) → **Closed testing** (satisfies the requirement above) →
**Open testing / beta** → **Production**.

---

## 5. First upload

1. **Test and release → Testing → Internal testing → Create new release**
2. When asked about signing, **use Play App Signing** (let Google generate the
   app signing key — the default and the right choice)
3. Upload `build/app/outputs/bundle/release/app-release.aab`
4. Release name: `1.0.17 (17)`. Add release notes.
5. **Save → Review release → Start rollout**

First upload of a brand-new app takes **1–2 hours** to become installable by
testers. Later uploads take ~10 minutes.

> **versionCode must increase on every single upload.** It comes from
> `pubspec.yaml` (`version: 1.0.17+17` → versionCode 17). Bump the `+N` before
> each new build or Play rejects it.

---

## 6. In-app purchases

`docs/iap-setup.md` §3 and §4 already cover this end to end. The Play-specific
order of operations:

1. **Monetise → Products → In-app products** — create all 5 packs with IDs
   matching iOS exactly: `com.walhallaa.spygame.v02202404.bundle.istanbul`,
   `.paris`, `.tokyo`, `.stockholm`, `.cyberpunk`. Type: one-time, non-consumable.
2. **Setup → License testing** — add your test Google accounts so you can buy
   without being charged.
3. Create the **service account JSON** — see the walkthrough below.
4. **RevenueCat → Project Settings → Apps → Add app → Play Store** — field
   values below.
5. Copy the **`goog_...` public SDK key** from RevenueCat → Project Settings →
   API keys.

### RevenueCat "New Play Store configuration" — what goes in each field

| Field | Value |
|---|---|
| App name | `WhereAmI (Play Store)` — just a label inside RevenueCat, any name works |
| Google Play package name | `com.walhallaa.spygame.v02202404` |
| Custom URL Scheme | **Leave blank** — only used for RevenueCat paywall previews, and the app registers no custom scheme (deep links use https App Links to `whereami-ea329.web.app`) |
| Service Account Credentials JSON | The file from the walkthrough below |
| Financial reports bucket ID | **Optional, skip for now** — only for revenue reconciliation. Found later at Play Console → Download reports → Financial, as a `pubsite_prod_...` bucket ID |

### Creating the service account JSON

This is the one genuinely fiddly part, because it spans two different Google
consoles. Both are free.

**Part A — Google Cloud Console** (`console.cloud.google.com`)

1. Pick or create a project. **This is currently `monkeyhub-2b2c6`** — the
   other app's project, reused deliberately. A GCP project is only a container
   for the service account identity and Pub/Sub topics; the app, purchases and
   developer account all live in Play Console, so sharing one is functionally
   harmless. The only real cost is that `roles/pubsub.editor` is project-wide,
   so this key could touch any Pub/Sub topic in that project (there are none
   today). Splitting it out later means a new service account, a new Play
   Console invite, and another propagation wait — not worth doing unless
   monkeyhub starts using Pub/Sub for something of its own.
2. **APIs & Services → Library** → enable **all three**:
   - **Google Play Android Developer API** (purchase validation)
   - **Cloud Pub/Sub API** (real-time developer notifications)
   - **Play Developer Reporting API**
3. **IAM & Admin → Service Accounts → Create service account**
   - Name: `revenuecat-validator` (any name)
4. **Do not skip the "Grant this service account access to project" step.**
   Add both roles:
   - **Pub/Sub Editor** (`roles/pubsub.editor`)
   - **Monitoring Viewer** (`roles/monitoring.viewer`)
5. Click the new service account → **Keys** tab → **Add key → Create new key → JSON**
6. A `.json` file downloads. **This is the file RevenueCat wants.** Treat it
   like a password — it can read your purchase data.
7. Copy the service account's email address, which looks like
   `revenuecat-validator@your-project.iam.gserviceaccount.com`

> **Two separate permission systems, and this is where people get stuck.**
> The IAM roles above are *Google Cloud* permissions, granted to the service
> account inside the GCP project. The permissions in Part B below are *Play
> Console* permissions, granted to the same account inside your developer
> account. Getting one right does not help the other. Missing IAM roles produce
> "credentials do not have permissions to access the Google Cloud Pub/Sub API";
> missing Play permissions produce subscriptions/monetization API failures.

**Part B — Play Console** (`play.google.com/console`)

7. **Users and permissions → Invite new user** → paste the service account's
   real `client_email` from the JSON. It ends in
   `@<gcp-project>.iam.gserviceaccount.com` — Play accepts a typo'd address
   silently and you only discover it when RevenueCat rejects the credentials.
8. Scope the invite to **this app only** (App permissions), not account-wide,
   and grant:
   - **View app information and download bulk reports** — reads the product catalog
   - **View financial data** — this is what grants Purchases API access
   - **Manage orders and subscriptions** — refunds, cancellations, purchase state
   - **Release apps to testing tracks** — only if you reuse this same JSON for
     Codemagic uploads (§8), which saves creating a second service account

   Leave everything else unticked, and **never grant Admin** — it lets the key
   holder invite further users to your developer account.
9. **Invite user**
10. Wait ~5 minutes, sometimes up to 24 hours, for Play to propagate access.
    If RevenueCat rejects the JSON immediately, this propagation delay is
    almost always the reason — wait and retry rather than regenerating the key.

The same JSON also works as the Codemagic Google Play integration in §8 — you
only need to create it once, though you may want to add the *Release to testing
tracks* permission if you reuse it for CI uploads.

### Fixing an existing service account that's missing the IAM roles

If you created the account without the roles in step 4, don't make a second
one. Open **Google Cloud Shell** (the `>_` icon in the Cloud Console top bar —
it's a browser terminal with `gcloud` preinstalled, nothing to install locally)
and run, substituting your project and service account:

```bash
PROJECT=monkeyhub-2b2c6
SA=revenuecat-validator@$PROJECT.iam.gserviceaccount.com

gcloud config set project $PROJECT
gcloud services enable pubsub.googleapis.com \
                       playdeveloperreporting.googleapis.com \
                       androidpublisher.googleapis.com
gcloud projects add-iam-policy-binding $PROJECT \
  --member="serviceAccount:$SA" --role="roles/pubsub.editor"
gcloud projects add-iam-policy-binding $PROJECT \
  --member="serviceAccount:$SA" --role="roles/monitoring.viewer"
```

Then in RevenueCat click **Replace** and re-upload the JSON to force a
re-validation. IAM roles attach to the *identity*, not to the key file, so the
existing JSON stays valid — regenerating the key is only worth trying if
re-uploading doesn't clear the error.

> RevenueCat publishes an automated Cloud Shell script that does all of this,
> but it **creates a brand-new service account**. Use the commands above
> instead if you already invited one to Play Console, otherwise you have to
> redo the Play Console invite for the new account too.

### Credential state as verified on 2026-07-31

Probed directly against the Play Developer API with the service account key:

| Check | Result | Meaning |
|---|---|---|
| `edits.insert` | 200 | App reachable, Play access granted |
| `subscriptions` (list) | 204 | *View financial data* IS granted |
| `inappproducts` (legacy) | 403 "migrate to the new publishing API" | Legacy endpoint retired for this app — expected, not fixable |
| `onetimeproducts` | 404 | No products exist yet |

So the credentials themselves are complete. If RevenueCat still shows
"Credentials need attention", the cause is the app being an empty shell (no
build, no products) plus Google's propagation lag — not a permission gap.
Don't go re-granting things.

> **You cannot create in-app products until a build has been uploaded.** Play
> Console keeps the Monetise → Products section closed until the app has at
> least one uploaded APK/AAB on some track. That's why the ordering below is
> strict: build → upload → products → revalidate RevenueCat.

### Faster validation

Credentials normally take up to 36 hours to go green. A known workaround:
in Play Console open **Monetise → Products → In-app products**, edit any
product's description, save, then revert it. This nudges Google into
refreshing the credential state, often within minutes. Not guaranteed, but
costs nothing.

### 🔴 Then do this — purchases are currently dead on Android

`REVENUECAT_ANDROID_KEY` is **empty** in `.env.local`, so the bundle you're
about to upload has no Android RevenueCat key and the marketplace runs in
browse-only mode — no Buy, no Restore. That's harmless for the first upload
(products don't exist yet anyway), but before any real release:

```bash
# add the goog_ key to .env.local, then
./build_android.sh
```

`build_android.sh` warns you if the key is still missing. A plain
`flutter build appbundle` silently ships without it — always use the script.

---

## 6b. Deep links (Android App Links)

`web/.well-known/assetlinks.json` is served from `whereami-ea329.web.app` and
gates the `autoVerify` intent filter in `AndroidManifest.xml:41-47`. It used to
contain a literal `REPLACE_WITH_RELEASE_SHA256_BEFORE_SHIPPING` placeholder,
which fails verification — replaced with the real upload-key fingerprint.

**Resolved 2026-07-31.** All three fingerprints are live and confirmed by
Google's Digital Asset Links API (3 statements, no errors):

| Fingerprint | Covers |
|---|---|
| `A4:94:08:…` | debug builds (local dev) |
| `62:A8:F5:…` | upload key — sideloaded release APKs |
| `4D:49:2F:3B:…` | **Play App Signing key** — everything installed from Play |

The third one is the one that matters for real users: Play re-signs your bundle,
so Play-installed apps present Google's certificate, not your upload key.

### Getting the Play app signing fingerprint without the console

Play Console has moved this page around and it is currently hard to find. Pull
it from the API instead — `generatedApks` reports the certificate Google used
to sign the delivered APKs:

```
GET https://androidpublisher.googleapis.com/androidpublisher/v3/applications/<pkg>/generatedApks/<versionCode>
→ generatedApks[].certificateSha256Hash
```

It is returned **already colon-separated uppercase hex** — do not base64-decode
it (that silently produces a 48-byte value that looks plausible and is wrong).
A 404 means Play is still processing the bundle; the first upload of a new app
takes 1-2 hours.

### Verifying a change

Don't trust a visual diff — ask Google's verifier:

```bash
curl -s "https://digitalassetlinks.googleapis.com/v1/statements:list\
?source.web.site=https://whereami-ea329.web.app\
&relation=delegate_permission/common.handle_all_urls"
```

One statement per fingerprint and no `errorCode` means Android will verify.

### Deploying

Hosting for `whereami-ea329` belongs to **muratcankoc@gmail.com**, not the
maymunpartisi0 account the Firebase CLI defaults to. Deploy with:

```bash
./scripts/build_web.sh
firebase deploy --only hosting --project whereami-ea329 --account muratcankoc@gmail.com
```

## 7. Push notifications gap

The Android build intentionally has **no `google-services.json`**
(`android/app/build.gradle.kts:13` applies the Firebase plugin only if the file
exists). That means FCM is disabled, so the silent push that wakes the app for
the round-end transition **does not fire on Android**. Fine for sideloading,
noticeably worse than iOS for public users.

To close it:
1. Firebase Console → your project → **Add app → Android**
2. Package name `com.walhallaa.spygame.v02202404`, SHA-1 from §0
3. Download `google-services.json` → place at `android/app/google-services.json`
4. Confirm it's gitignored, and add it to Codemagic as an encrypted file
5. Rebuild — the Gradle plugin picks it up automatically, no code change

---

## 8. Automating future releases

Once the first manual upload has landed, Codemagic can ship every push to
`main`, mirroring the iOS workflow. `ANDROID_DEPLOY_PLAN.md` §B2 has the
workflow spec. You'll need to give Codemagic:

- **Code signing identities → Android keystores**: upload `spygame_upload.jks`,
  reference name `spygame_upload`, alias `upload`, both passwords
- **Teams → Integrations → Google Play**: paste the service account JSON from §6.3
- Environment variables: `REVENUECAT_IOS_KEY`, `REVENUECAT_ANDROID_KEY`

---

## Checklist

- [ ] App created in Play Console with the exact package name
- [ ] `.jks` + password saved to password manager
- [ ] Store listing (EN + TR) filled from `docs/app-store-listing.md`
- [ ] App icon 512×512 + feature graphic 1024×500 + 2 screenshots uploaded
- [ ] Privacy policy URL verified reachable
- [ ] Content rating, target audience, data safety, ads forms completed
- [ ] Closed-testing requirement checked for your account type
- [ ] First `.aab` uploaded to internal testing
- [ ] 5 in-app products created in Play Console
- [ ] Service account JSON created and invited
- [ ] RevenueCat Play app configured, `goog_` key in `.env.local`
- [ ] Rebuilt with `./build_android.sh` so purchases work
- [ ] `google-services.json` added so Android push works
- [ ] Codemagic wired for automatic releases
