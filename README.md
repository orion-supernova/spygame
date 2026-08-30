<div align="center">

# Where am I?

**Everyone shares a secret location. One of you doesn't.**

A real-time party game of bluffing and deduction for 3–12 people in the same room.
No accounts. No ads. No app deciding who won — just you, your friends, and a ticking clock.

[![App Store](https://img.shields.io/badge/App_Store-Download-0D96F6?style=for-the-badge&logo=apple&logoColor=white)](https://apps.apple.com/app/idAPP_STORE_ID)
[![Google Play](https://img.shields.io/badge/Google_Play-Download-414141?style=for-the-badge&logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=com.walhallaa.spygame.v02202404)

<img src="docs/media/hero.gif" alt="Naming yourself, creating a room, and sharing the four-letter code" width="280">

</div>

---

## How it plays

Somebody creates a room and shares a 4-letter code. Everyone joins from their own phone.

Each round, you secretly see **where you are** and **who you are** there — Trauma Ward, Night Shift Surgeon. Everybody sees the same location. Except one player, who sees nothing but *"you don't know."* That's the spy.

Then you just… talk. Ask each other questions. Answer too vaguely and people get suspicious. Answer too specifically and you hand the spy the location. When the timer runs out, argue it out. The spy wins by staying invisible. Everyone else wins by pointing at the right person.

The app never votes for you. It just deals the cards and runs the clock.

<div align="center">
<table>
<tr>
<td align="center"><img src="docs/media/role.gif" alt="Press and hold to reveal your role" width="220"><br><sub><b>Press and hold</b><br>Your location and your role.<br>Or, if you're unlucky, neither.</sub></td>
<td align="center"><img src="docs/media/themes.gif" alt="Switching room themes" width="220"><br><sub><b>Reskin the whole room</b><br>Classic, Cyberpunk,<br>Victorian London, Wild West</sub></td>
<td align="center"><img src="docs/media/reveal.gif" alt="The spy is revealed" width="220"><br><sub><b>Then the argument</b><br>Round's up. Talk it out,<br>then find out who it was.</sub></td>
</tr>
</table>
</div>

## Why it's good

**Nobody has to babysit the timer.** The countdown lives on the server, not your phone. Lock the screen, take a call, drop off Wi-Fi and come back — everyone's clock still reads the same number.

**Put the phone down and play.** On iOS the round runs as a Live Activity; on Android it's a live countdown in your notification shade. The clock stays visible while you're mid-argument with your screen off.

**Zero friction to start.** No account, no email, no invite links to chase. Four letters and you're in. One phone works too — just pass it around.

**Tunable.** 1–3 spies, 1–15 minute rounds, 1–10 rounds per game.

**Actually private.** No ads, no analytics SDKs, no tracking. No location, contacts, camera, or mic access. The only thing stored on your device is a random ID so you can rejoin if the app dies mid-game.

**English and Turkish**, right down to the role names.

## Packs

24 locations are free forever, each with 11 unique roles. If you want more, there are 15 optional one-time-purchase packs — 12 cities and 3 full themes.

> **Cities** — Istanbul, Paris, Tokyo, Stockholm, New York, London, Rome, Cairo, Rio, Berlin, Dubai, Bangkok
>
> **Themes** — Cyberpunk, Wild West, Victorian London

<div align="center">
<table>
<tr>
<td align="center"><img src="docs/media/locations.gif" alt="Host toggling which locations are in play" width="240"><br><sub><b>Host picks the deck</b><br>Toggle any location off before you start.<br>Locked in when the game begins, so nobody<br>can shuffle the pool mid-round.</sub></td>
<td align="center"><img src="docs/media/packs.gif" alt="The location packs store" width="240"><br><sub><b>Buy once, keep it</b><br>No subscription, no currency,<br>no timed unlocks.</sub></td>
</tr>
</table>
</div>

Themes aren't just extra cards. Buy Wild West and the whole app becomes a saloon — kraft paper, wanted-poster role cards, a flip-clock counting you down. Victorian London gets fog, calling cards, and a pocket watch. The host picks it; everyone in the room sees it at once.

## Under the hood

Flutter + Riverpod on the front, [Convex](https://convex.dev) on the back. Room state streams over websockets, so a player joining shows up on twelve phones at once with no polling and no refresh button.

The interesting bits:

- **Server-authoritative rounds.** Clients derive the countdown from a server timestamp instead of counting down locally, so backgrounding never desyncs anyone.
- **Secrets stay server-side.** Your role and the location are never in the room subscription payload — they're fetched per-player, so nobody can read the answer out of the wire.
- **Silent push to keep the widget alive.** iOS Live Activities and Android's ongoing notification are updated by silent APNs/FCM, the only way to move a chronometer while the app is fully suspended.
- **Skins as a theme extension.** A pack swaps an `AppSkin` `ThemeExtension` — colors, fonts, textures, timer widget, role card frame — and syncs it to every device in the room.

```bash
flutter pub get
flutter run                 # ships pointed at the hosted backend
flutter test
```

Running your own backend:

```bash
npm install
npx convex dev              # from the repo root, not from convex/
npx convex run locations:seed
```

## Say hi

Ideas for a pack, a feature, or a bug you hit — [open an issue](https://github.com/orion-supernova/spygame/issues) or email **info@walhallaa.com**. Every message gets read.

<div align="center">
<sub>Built by <a href="https://walhallaa.com">Murat Can Koç</a> · <a href="https://walhallaa.com/whereami-privacy-terms">Privacy & Terms</a></sub>
</div>
