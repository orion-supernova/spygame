#!/usr/bin/env bash
# Record a screen capture (or convert a clip you already have) into a
# README-ready GIF.
#
#   ./scripts/record-gif.sh hero                      # record booted iOS simulator, Ctrl-C to stop
#   ./scripts/record-gif.sh lobby --android           # record a connected Android device / emulator
#   ./scripts/record-gif.sh role ~/Desktop/clip.mov   # convert an existing clip
#
# Options:
#   --trim START:END   seconds to keep, e.g. --trim 1.3:12.7
#                      comma-separate to stitch segments and skip what's between:
#                      --trim 0.6:4.3,5.9:10.0
#   --speed N          playback multiplier, e.g. --speed 1.3 (1.0 = untouched)
#   --width N          output width in px (default 360; the README hero uses 440)
#
# Output lands in docs/media/<name>.gif.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/docs/media"
FPS=14        # plenty for UI motion; higher just doubles the file for no gain
WIDTH=360     # ~2x the README's display size, so it stays sharp on retina
MAX_MB=8      # bigger renders fine on GitHub but feels broken on a slow line
TRIM=""
SPEED="1.0"

NAME=""
SOURCE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --trim)    TRIM="$2"; shift 2 ;;
    --speed)   SPEED="$2"; shift 2 ;;
    --width)   WIDTH="$2"; shift 2 ;;
    --android) SOURCE="--android"; shift ;;
    -*)        echo "unknown option: $1" >&2; exit 1 ;;
    *)         if [[ -z "$NAME" ]]; then NAME="$1"; else SOURCE="$1"; fi; shift ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "usage: $0 <name> [source.mov | --android] [--trim S:E] [--speed N] [--width N]" >&2
  exit 1
fi

command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg is required.  brew install ffmpeg" >&2; exit 1; }

mkdir -p "$OUT_DIR"
RAW="$(mktemp -t "spygame-$NAME").mov"
trap 'rm -f "$RAW"' EXIT

case "$SOURCE" in
  "")
    command -v xcrun >/dev/null || { echo "xcrun not found — pass a source file instead" >&2; exit 1; }
    echo "Recording the booted iOS simulator. Press Ctrl-C when you're done."
    # Ctrl-C is how simctl is meant to be stopped, and SIGINT hits the whole
    # foreground group — so the parent has to ignore it or this script dies
    # before it ever converts anything.
    trap '' INT
    xcrun simctl io booted recordVideo --codec h264 --force "$RAW" || true
    trap - INT
    ;;
  --android)
    command -v adb >/dev/null || { echo "adb not found — install platform-tools" >&2; exit 1; }
    echo "Recording the connected Android device (max 180s). Press Ctrl-C when you're done."
    trap '' INT
    adb shell screenrecord --time-limit 180 /sdcard/spygame-rec.mp4 || true
    trap - INT
    sleep 1
    adb pull /sdcard/spygame-rec.mp4 "$RAW" >/dev/null
    adb shell rm /sdcard/spygame-rec.mp4 || true
    ;;
  *)
    [[ -f "$SOURCE" ]] || { echo "no such file: $SOURCE" >&2; exit 1; }
    cp "$SOURCE" "$RAW"
    ;;
esac

[[ -s "$RAW" ]] || { echo "nothing was recorded" >&2; exit 1; }

# Build the pre-palette filter chain: optional trim (one or more segments,
# stitched), optional speed, then the fps/scale every output shares.
if [[ -z "$TRIM" ]]; then
  PRE="[0:v]setpts=PTS-STARTPTS[t];"
else
  IFS=',' read -ra SEGS <<< "$TRIM"
  PRE=""
  for i in "${!SEGS[@]}"; do
    seg="${SEGS[$i]}"
    PRE+="[0:v]trim=${seg%%:*}:${seg##*:},setpts=PTS-STARTPTS[s$i];"
  done
  if [[ ${#SEGS[@]} -eq 1 ]]; then
    PRE+="[s0]null[t];"
  else
    for i in "${!SEGS[@]}"; do PRE+="[s$i]"; done
    PRE+="concat=n=${#SEGS[@]}:v=1[t];"
  fi
fi
PRE+="[t]"
[[ "$SPEED" != "1.0" ]] && PRE+="setpts=PTS/$SPEED,"
PRE+="fps=$FPS,scale=$WIDTH:-1:flags=lanczos[c]"

# One shared 256-colour palette across the whole clip — this is what keeps
# gradients from banding into mush.
ffmpeg -y -loglevel error -i "$RAW" -filter_complex \
  "$PRE;[c]split[s0][s1];[s0]palettegen=stats_mode=diff[p];\
[s1][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle" \
  "$OUT_DIR/$NAME.gif"

BYTES=$(stat -f%z "$OUT_DIR/$NAME.gif" 2>/dev/null || stat -c%s "$OUT_DIR/$NAME.gif")
SECS=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT_DIR/$NAME.gif" 2>/dev/null || echo "?")
printf '→ docs/media/%s.gif  (%.1fMB, %ss)\n' "$NAME" "$(echo "$BYTES / 1000000" | bc -l)" "$SECS"
if (( BYTES / 1000000 > MAX_MB )); then
  echo "   heads up: over ${MAX_MB}MB. Trim it shorter, or drop --width."
fi
