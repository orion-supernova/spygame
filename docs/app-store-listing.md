# App Store / Play Store listing

Copy/paste-ready metadata for App Store Connect and Google Play Console. All character counts are within both stores' limits. Fill the same values into Play Console where field names overlap.

---

## App identity

| Field | Value |
|---|---|
| App name | `Where am I?` |
| Bundle ID (iOS) | `com.walhallaa.spygame.v02202404` |
| Package name (Android) | `com.walhallaa.spygame.v02202404` |
| SKU | `whereami-001` |
| Primary language | English (U.S.) |
| Additional languages | Turkish |

## Categorization

| Field | Value |
|---|---|
| Primary category | Games |
| Primary subcategory | Family |
| Secondary subcategory | Trivia |
| Age rating | 4+ (no objectionable content; in-app purchases declared) |
| Contains in-app purchases | Yes (5 non-consumable location packs, $0.99 each) |
| Contains ads | No |
| Content rights | I (or my company) own or have licensed all rights |

---

## App Store Connect — English (U.S.)

### Subtitle (max 30 characters)

```
Find the spy. Or be one.
```

(24 chars) — Tagline shown directly under the app name in App Store search results.

### Promotional Text (max 170 characters; editable without resubmission)

```
Everyone shares a secret location. One of you doesn't. Find them — or blend in. Optional location packs: Istanbul, Paris, Tokyo, Stockholm, Cyberpunk.
```

(167 chars)

### Description (max 4000 characters)

```
Where am I? is a real-time party game of bluffing and deduction for your living room, your road trip, your dinner table.

Everyone shares a secret location — except for one player, the spy.

The spy's job: blend in, ask careful questions, and figure out where everyone else is. Everyone else's job: look the spy in the eye and find them out.

No vote, no scoreboard, no app deciding who won — just the players, in the same room, talking it out.

— HOW IT WORKS —

• One person creates a room, shares the 4-letter code, friends join from their phones (or pass one phone around).
• Each round, everyone secretly sees their location and role — except the spy, who only sees "you don't know."
• Ask each other questions. Answer too vaguely and people will suspect you. Answer too specifically and you'll give the location away.
• When time runs out, debate. Decide who the spy is. The spy wins by staying hidden; everyone else wins by pointing them out.

— WHAT'S INSIDE —

• 3 to 12 players
• 24 included locations (Beach, Hospital, Submarine, Theater, and 20 more), each with 11+ unique roles
• Customizable round timer (3–10 minutes) and number of rounds
• Live Activity on iOS / ongoing notification on Android — the round stays visible while you debate, even when the screen is off
• Optional location packs (one-time purchase):
  – Istanbul: bazaars, ferries, and stray cats
  – Paris: cafés, métro, and museum heists
  – Tokyo: karaoke, capsule hotels, and code
  – Stockholm: saunas, Vasa, and herring
  – Cyberpunk: neon, chrome, and bad decisions

— PRIVACY-FIRST —

• No accounts, sign-up, or email required.
• No ads. No analytics SDKs. No tracking.
• No location, contacts, camera, or microphone access.
• Only a randomly generated identifier is stored on your device so you can rejoin a game in progress.

— FEEDBACK —

Got an idea for a new location pack or a feature? Email muratcankoc@gmail.com. Every message is read.
```

(~1950 characters; well under 4000)

### Keywords (max 100 characters, comma-separated, no spaces)

```
spyfall,bluff,party,deduction,family,multiplayer,group,detective,location,role,trivia,word
```

(90 characters)

> **Don't include:** the app name (auto-indexed), category words ("game", "games"), or words from the description (Apple deprioritizes them). **Do include:** the genre's most-searched alias ("spyfall"), the social context ("party", "family", "group"), and the game mechanic ("bluff", "deduction").

### What's New (release notes)

For version 1.0.x (initial release):

```
First release. 24 included locations, 5 optional location packs, and 3–12 players per game. Designed for face-to-face play — no in-app voting, no scoreboard, just conversation.
```

For minor updates, follow this template:

```
• Headline change in this version (one-line bullet)
• Bug fix or polish item
• Bug fix or polish item

Feedback: muratcankoc@gmail.com
```

### Support URL

```
https://walhallaa.com/whereami-privacy-terms
```

### Marketing URL (optional)

```
https://walhallaa.com
```

### License Agreement (EULA)

**Recommendation: leave blank** in App Store Connect → **App Information → License Agreement**. Apple's [Standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) then applies automatically and covers every clause Apple requires (third-party beneficiary, warranty disclaimers, embargoed-country compliance, product-claims responsibility, etc.).

Why not the custom one at `https://walhallaa.com/whereami-eula`? A custom EULA *replaces* Apple's standard rather than supplementing it, so it must include all of Apple's required clauses. Ours focuses on app-specific terms (in-app purchases, display-name moderation, Turkish governing law) and doesn't carry every required boilerplate clause — supplying it could prompt App Review questions. The Terms & Conditions on `https://walhallaa.com/whereami-privacy-terms` already cover acceptable-use, IAP, and refund handling for users.

The custom EULA stays published as supplemental public reference (linked from the project listing on walhallaa.com), matching the existing pattern for MonkeyHub / MonkeyChat. It is not used by App Store Connect or Play Console.

### Copyright

```
2026 Murat Can Koç
```

### App Review Information

**Sign-in required**: No.

**Demo account**: N/A — the app is anonymous. No login.

**Notes for the reviewer**:

```
"Where am I?" is a Spyfall-style social deduction party game played in person. Players are in the same room and communicate verbally — there is no in-app chat, voice, or messaging.

To test multiplayer:
1. Tap CREATE A ROOM, type any codename, and a 4-letter code is shown.
2. On a second device or simulator, tap JOIN ROOM and enter that code.
3. Both devices tap "I'M READY" → host taps START GAME.

To test in-app purchases:
1. From the welcome screen, tap MARKETPLACE.
2. Tap any locked bundle (e.g. Istanbul).
3. Tap UNLOCK · $0.99. A sandbox prompt appears.
4. After purchase, the bundle is OWNED and its locations show up in the next round.
5. Tap "Restore purchases" in the marketplace header to test cross-device restore.

Display names are user-typed but only visible to players already in the same room (max 12, joined via short code shared by the host). There is no public username directory, friends list, or chat surface — every interaction outside of the game state happens face-to-face.

The app uses Convex for backend state, RevenueCat for in-app purchase validation, and Firebase Cloud Messaging on Android for round-end notifications. iOS uses Live Activity, not FCM.
```

### App Privacy ("Data" section in App Store Connect)

**Data collected and used to track you across other apps**: None.

**Data linked to your identity**: None. (The app has no accounts, no email, no real-name field.)

**Data not linked to your identity**:

| Data Type | Used for |
|---|---|
| User-generated content (display name typed in the app) | App Functionality |
| Identifiers (random per-install UUID) | App Functionality |
| Diagnostics (crash data, performance metrics) | App Functionality |
| Purchases (purchase history, processed by Apple + RevenueCat) | App Functionality |

In all cases tick "Data is not linked to the user's identity" — there is no account system to link it to.

---

## App Store Connect — Turkish

### Subtitle

```
Casusu bul. Ya da casus ol.
```

(28 chars)

### Promotional Text

```
Herkes ortak bir gizli mekânı bilir. Birinizin haberi yok. Onu bul — ya da ele verme. İsteğe bağlı mekân paketleri: İstanbul, Paris, Tokyo, Stockholm, Cyberpunk.
```

### Description

```
Where am I? — gerçek zamanlı bir blöf ve sezgi parti oyunu. Salonun, yolculuğun, yemek masan için.

Herkesin paylaştığı bir gizli mekân vardır — bir oyuncu hariç: casus.

Casusun görevi: kim olduğunu belli etmemek, dikkatli sorular sormak, herkesin nerede olduğunu çözmek. Diğerlerinin görevi: casusun gözüne bakıp onu yakalamak.

Oylama yok, skor tablosu yok, kimin kazandığına karar veren bir uygulama yok — sadece oyuncular, aynı odada, konuşarak çözüyor.

— NASIL OYNANIR —

• Biri oda kurar, 4 harfli kodu paylaşır, arkadaşlar telefonlarından katılır (ya da tek telefonu el ele dolaştırırsınız).
• Her tur, herkes mekânını ve rolünü gizlice görür — casus hariç. O sadece "bilmiyorsun" yazısını görür.
• Birbirinize sorular sorun. Çok belirsiz cevap verirseniz şüphe çekersiniz. Çok spesifik cevap verirseniz mekânı ele verirsiniz.
• Süre dolduğunda tartışın. Casusun kim olduğuna karar verin. Casus saklanarak kazanır; diğerleri onu bularak.

— İÇİNDE NE VAR —

• 3 ila 12 oyuncu
• 24 hazır mekân (Plaj, Hastane, Denizaltı, Tiyatro ve 20 tane daha) — her birinde 11+ benzersiz rol
• Tur süresi (3–10 dk) ve tur sayısı ayarlanabilir
• iOS'ta Live Activity, Android'de kalıcı bildirim — siz tartışırken tur ekranda görünür kalır
• İsteğe bağlı mekân paketleri (tek seferlik satın alma):
  – İstanbul: pazarlar, vapurlar ve sokak kedileri
  – Paris: kafeler, metro ve müze soygunları
  – Tokyo: karaoke, kapsül oteller ve kod
  – Stockholm: saunalar, Vasa ve ringa balığı
  – Cyberpunk: neon, krom ve kötü kararlar

— GİZLİLİK ÖNCELİKLİ —

• Hesap, kayıt veya e-posta gerekmez.
• Reklam yok. Analitik SDK yok. Takip yok.
• Konum, rehber, kamera veya mikrofon erişimi yok.
• Yalnızca cihazında saklanan rastgele bir kimlik — devam eden oyuna geri dönebilesin diye.

— GERİ BİLDİRİM —

Yeni bir mekân paketi veya özellik fikrin mi var? muratcankoc@gmail.com adresine yaz. Her mesaj okunuyor.
```

### Keywords (TR)

```
casus,blöf,parti,grup,aile,arkadaş,oyun,konum,detektif,rol,çoklu,çocuk
```

---

## Google Play Console

Most fields mirror App Store Connect. Play-specific fields:

| Field | Value |
|---|---|
| Title (max 30 chars) | `Where am I?` |
| Short description (max 80 chars) | `Find the spy hiding in your circle. A real-time party game for 3–12 friends.` (76 chars) |
| Full description | Same as App Store description above |
| Short description (TR) | `Aranızdaki casusu bul. 3–12 arkadaş için gerçek zamanlı parti oyunu.` (68 chars) |
| App category | `Card` (closest fit; Spyfall is a social deduction card-style game) |
| Content rating | Everyone (complete the IARC questionnaire — no violence, no chat, no UGC moderation needed) |
| Tags | `Card`, `Party`, `Family`, `Friends` |
| Contact email | `muratcankoc@gmail.com` |
| Contact website | `https://walhallaa.com` |
| Privacy policy URL | `https://walhallaa.com/whereami-privacy-terms` |

---

## Screenshots checklist

You'll need screenshots for the following devices. Take from the actual app (not mockups). Keep the wordmark visible.

**iOS** (App Store Connect requires at least one set per supported display size):
- iPhone 6.9" (iPhone 16 Pro Max — 1290 × 2796) — required
- iPhone 6.7" (iPhone 14 Pro Max — 1290 × 2796) — usually accepted as a duplicate of 6.9"
- iPad 13" (iPad Pro M4 — 2064 × 2752) — only if the app supports iPad
- App Preview video (optional, 15–30 seconds, .mp4)

**Android** (Play Console):
- Phone screenshots: at least 2, max 8. 1080 × 1920 or higher.
- Feature graphic: 1024 × 500 (mandatory, used as the banner on the store listing).
- App icon: 512 × 512 PNG.
- (Optional) 7" tablet, 10" tablet — only if you support these.

**Suggested screenshot sequence** (5 frames):
1. Welcome screen — wordmark + tagline.
2. Lobby with room code chip — "easy to host."
3. Role card revealed (mid-press hold) — the dramatic moment.
4. Round timer ticking — "the clock is the antagonist."
5. Marketplace — show the location packs to surface IAPs early.

---

## Pre-launch checklist

- [ ] All five IAPs created in App Store Connect (status: Ready to Submit).
- [ ] All five IAPs created in Google Play Console (status: Active).
- [ ] RevenueCat dashboard configured (5 entitlements, 5 packages in `default` offering, current).
- [ ] `.env.local` filled with `REVENUECAT_IOS_KEY` and `REVENUECAT_ANDROID_KEY`.
- [ ] App icon (1024 × 1024 for iOS, 512 × 512 for Android) generated and added to Xcode + `android/app/src/main/res/`.
- [ ] At least 5 screenshots taken on a real device.
- [ ] Privacy Policy URL is reachable (https://walhallaa.com/whereami-privacy-terms).
- [ ] Apple Developer agreements (Paid Apps + Tax + Banking) all green in App Store Connect.
- [ ] Play Console payments profile linked.
- [ ] App built with the dart-define keys via `./deploy.sh`.
- [ ] iOS build uploaded to TestFlight; sandbox-tested end-to-end (purchase + restore + refund).
- [ ] Android build uploaded to internal testing track; sandbox-tested end-to-end.
- [ ] App Review Notes pasted into App Store Connect (see above).
