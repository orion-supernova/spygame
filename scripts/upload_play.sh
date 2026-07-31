#!/bin/bash
# Uploads a signed .aab to a Google Play track via the Play Developer API.
#
#   scripts/upload_play.sh                          # internal track, default aab
#   scripts/upload_play.sh --track beta             # open testing
#   scripts/upload_play.sh --aab path/to.aab
#
# Credentials: a Play service account JSON, found via (in order)
#   $PLAY_SERVICE_ACCOUNT_JSON, .env.local's PLAY_SERVICE_ACCOUNT_JSON, or --json
#
# The service account needs "Release apps to testing tracks" in Play Console
# (Users and permissions). Purchase-validation permissions are NOT enough.
#
# Note: Google rejects a `completed` release on an app that has never been
# published — the script detects that and retries as a `draft`, which you then
# roll out from the console. Every later upload can go straight to completed.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

PKG="com.walhallaa.spygame.v02202404"
TRACK="internal"
AAB="build/app/outputs/bundle/release/app-release.aab"
JSON="${PLAY_SERVICE_ACCOUNT_JSON:-}"
NOTES="Internal test build."

while [ $# -gt 0 ]; do
    case "$1" in
        --track) TRACK="$2"; shift 2 ;;
        --aab)   AAB="$2"; shift 2 ;;
        --json)  JSON="$2"; shift 2 ;;
        --notes) NOTES="$2"; shift 2 ;;
        *) echo "unknown arg: $1"; exit 1 ;;
    esac
done

if [ -z "$JSON" ] && [ -f .env.local ]; then
    JSON=$(grep -E "^[[:space:]]*PLAY_SERVICE_ACCOUNT_JSON=" .env.local 2>/dev/null \
           | head -1 | sed -E "s/^[^=]*=//; s/^['\"]//; s/['\"]$//")
fi
JSON="${JSON/#\~/$HOME}"

[ -f "$JSON" ] || { echo "❌ Service account JSON not found. Pass --json <path> or set PLAY_SERVICE_ACCOUNT_JSON in .env.local"; exit 1; }
[ -f "$AAB" ]  || { echo "❌ Bundle not found: $AAB — run ./build_android.sh first"; exit 1; }

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
jf() { python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get(sys.argv[2],''))" "$1" "$2"; }
js() { python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get(sys.argv[1],'')if isinstance(d,dict)else'')" "$1" 2>/dev/null; }
err() { python3 -c "
import json,sys
try:
    e=json.load(sys.stdin).get('error',{})
    print(e.get('status',''),'-',e.get('message',''))
except Exception: pass" 2>/dev/null; }

EMAIL=$(jf "$JSON" client_email); KEY=$(jf "$JSON" private_key)
echo "Package : $PKG"
echo "Track   : $TRACK"
echo "Bundle  : $AAB ($(du -h "$AAB" | cut -f1))"
echo "Account : $EMAIL"
echo

NOW=$(date +%s)
H=$(printf '%s' '{"alg":"RS256","typ":"JWT"}' | b64url)
C=$(printf '{"iss":"%s","scope":"https://www.googleapis.com/auth/androidpublisher","aud":"https://oauth2.googleapis.com/token","exp":%s,"iat":%s}' \
    "$EMAIL" "$((NOW+3600))" "$NOW" | b64url)
S=$(printf '%s.%s' "$H" "$C" | openssl dgst -sha256 -sign <(printf '%s' "$KEY") | b64url)
TOK=$(curl -s -X POST https://oauth2.googleapis.com/token \
      -d grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer \
      -d "assertion=$H.$C.$S" | js access_token)
[ -n "$TOK" ] || { echo "❌ Token exchange failed."; exit 1; }

API="https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$PKG"
UP="https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/$PKG"
AUTH=(-H "Authorization: Bearer $TOK")

echo "1/4 opening edit…"
EDIT=$(curl -s -X POST "$API/edits" "${AUTH[@]}" -H "Content-Length: 0" | js id)
[ -n "$EDIT" ] || { echo "❌ Could not open an edit."; exit 1; }
echo "    edit $EDIT"

cleanup() { [ -n "${EDIT:-}" ] && curl -s -o /dev/null -X DELETE "$API/edits/$EDIT" "${AUTH[@]}"; }

echo "2/4 uploading bundle (this is the slow part)…"
R=$(curl -s -w '\n%{http_code}' -X POST "$UP/edits/$EDIT/bundles?uploadType=media" \
    "${AUTH[@]}" -H "Content-Type: application/octet-stream" --data-binary @"$AAB")
CODE=$(tail -n1 <<<"$R"); BODY=$(sed '$d' <<<"$R")
if [ "$CODE" != "200" ]; then
    echo "❌ Upload failed (HTTP $CODE)"; err <<<"$BODY"
    [ "$CODE" = "403" ] && echo "   → The service account likely lacks 'Release apps to testing tracks'."
    cleanup; exit 1
fi
VC=$(js versionCode <<<"$BODY")
echo "    uploaded versionCode $VC"

assign() { # status
    curl -s -w '\n%{http_code}' -X PUT "$API/edits/$EDIT/tracks/$TRACK" "${AUTH[@]}" \
      -H "Content-Type: application/json" \
      -d "{\"track\":\"$TRACK\",\"releases\":[{\"versionCodes\":[\"$VC\"],\"status\":\"$1\",\"releaseNotes\":[{\"language\":\"en-US\",\"text\":$(python3 -c "import json,sys;print(json.dumps(sys.argv[1]))" "$NOTES")}]}]}"
}

echo "3/4 assigning to '$TRACK'…"
STATUS=completed
R=$(assign "$STATUS"); CODE=$(tail -n1 <<<"$R"); BODY=$(sed '$d' <<<"$R")
if [ "$CODE" != "200" ] && grep -qi "draft" <<<"$BODY"; then
    echo "    app has never been published — retrying as draft"
    STATUS=draft
    R=$(assign "$STATUS"); CODE=$(tail -n1 <<<"$R"); BODY=$(sed '$d' <<<"$R")
fi
if [ "$CODE" != "200" ]; then
    echo "❌ Track assignment failed (HTTP $CODE)"; err <<<"$BODY"; cleanup; exit 1
fi

echo "4/4 committing…"
R=$(curl -s -w '\n%{http_code}' -X POST "$API/edits/$EDIT:commit" "${AUTH[@]}" -H "Content-Length: 0")
CODE=$(tail -n1 <<<"$R"); BODY=$(sed '$d' <<<"$R")
if [ "$CODE" != "200" ]; then
    echo "❌ Commit failed (HTTP $CODE)"; err <<<"$BODY"; cleanup; exit 1
fi

EDIT=""   # committed; nothing to clean up
echo
echo "✅ versionCode $VC is on the '$TRACK' track as '$STATUS'."
[ "$STATUS" = "draft" ] && echo "   Open Play Console → Testing → ${TRACK^} testing and roll the draft out."
echo "   Play takes 1-2 hours to process the first build of a new app."
