# README media

The six GIFs the root README embeds. All were cut from screen recordings
taken on a real iPhone (1206×2622), which is why they have a status bar and
rounded corners — simulator capture reads as a mockup, device capture reads as
a shipped app. Keep that going.

| File | What it shows | Length | Source |
|---|---|---|---|
| `hero.gif` | Splash → codename → CREATE A ROOM → the code appears → ready up | 9.8s | `video.mov` 0–4.45s + 6.70–12.0s |
| `role.gif` | Round running on the flip clock, press-and-hold, THE SPY card | 5.9s | `gameplay.mov` 15.7–21.6s |
| `themes.gif` | Classic → Cyberpunk → Victorian London → Wild West, whole app reskinning | 8.5s | `gameplay.mov` 1.3–12.7s @ 1.3× |
| `reveal.gif` | Intermission — the spy's name decoding in | 3.1s | `round-end.mov` 0.15–3.3s |
| `locations.gif` | The host's location sheet, 24 of 24 enabled, scrolling the deck | 5.9s | `video.mov` 20.2–25.8s |
| `packs.gif` | "More to play" — Istanbul, Paris, Tokyo | 2.4s | `video.mov` 25.8–28.3s |

`video.mov` is one continuous 30s tour, cut into three: the sign-up moment
(`hero`), the location sheet (`locations`), and the store (`packs`). It's split
rather than shipped whole because a 28-second GIF at the top of a README is a
video nobody pressed play on — three short loops each make one point.

Two stretches are deliberately left on the floor:

- **4.45s → 6.70s**, the iOS notification permission dialog. Comma-separated
  `--trim` segments get stitched, so it vanishes and the codename screen runs
  straight into the lobby.
- **12s → 20s**, the round-settings tuning. Spies got set to 2 in a one-player
  room, so a red *"Too many spies for this player count"* sits under the button
  for that whole stretch. Nothing's broken — it's the validation working — but
  it's a red error message, and this is the front page. Worth re-recording with
  a second player joined if you want that section back.

Those boundaries aren't eyeballed — the dialog dims the screen, so it shows up
as a luma drop you can find precisely:

```bash
ffmpeg -i ~/Desktop/video.mov -vf "fps=20,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-" -f null -
```

Sustained values well below the surrounding frames = something is overlaying the
app. Worth re-running if you re-record, because the dialog never lands at the
same timestamp twice.

## Redoing one

```bash
brew install ffmpeg   # if you don't have it

# exactly how the four in this directory were built
./scripts/record-gif.sh hero      ~/Desktop/video.mov     --trim 0:4.45,6.70:12.0 --width 440
./scripts/record-gif.sh locations ~/Desktop/video.mov     --trim 20.2:25.8
./scripts/record-gif.sh packs     ~/Desktop/video.mov     --trim 25.8:28.3
./scripts/record-gif.sh themes ~/Desktop/gameplay.mov  --trim 1.3:12.7 --speed 1.3
./scripts/record-gif.sh role   ~/Desktop/gameplay.mov  --trim 15.7:21.6
./scripts/record-gif.sh reveal ~/Desktop/round-end.mov --trim 0.15:3.3

# or capture fresh footage
./scripts/record-gif.sh lobby --android   # a connected Android device
./scripts/record-gif.sh lobby             # the booted iOS simulator, Ctrl-C to stop
```

Two-pass palette conversion at 14fps, 440px for the hero and 360px for everything
else — roughly 2× the display size, so it stays sharp on retina without bloating.
All six come to ~6.5MB, and `themes.gif` is 2.8MB of that: it's the one clip
where the entire screen recolors, so interframe compression has nothing static
to lean on.

## If you shoot new footage

- Keep every clip under ~9 seconds. These are glances, and a glance that doesn't
  loop isn't one.
- Real codenames, not `test1`. People read them.
- Record the *state you want to sell*. The current `gameplay.mov` was shot with
  every pack unlocked (`54 of 54` locations), which is the aspirational view —
  that's fine here, just be deliberate about it.
- Anything past ~8MB per file feels broken on a slow connection.
