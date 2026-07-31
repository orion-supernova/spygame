#!/bin/bash
# Uploads an .ipa to App Store Connect. The iOS counterpart to
# scripts/upload_play.sh — upload only, build with ./build_ios.sh first.
#
#   scripts/upload_appstore.sh                 # newest .ipa in build/ios
#   scripts/upload_appstore.sh --ipa path.ipa
#
# Credentials come from .env.local:
#   APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID
#   APP_STORE_CONNECT_KEY_DIR (optional; defaults to ~/.appstoreconnect/private_keys)
#
# Auth is via ASC API key rather than an Xcode account, so this works on a
# machine with no signed-in Xcode — see the note in build_ios.sh.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# shellcheck source=scripts/lib/dotenv.sh
source scripts/lib/dotenv.sh

IPA=""
while [ $# -gt 0 ]; do
    case "$1" in
        --ipa) IPA="$2"; shift 2 ;;
        *) echo "unknown arg: $1"; exit 1 ;;
    esac
done

[ -f .env.local ] || { echo "❌ Missing .env.local at project root."; exit 1; }
load_env_file .env.local

if [ -z "$IPA" ]; then
    IPA="$(find build/ios -maxdepth 1 -type f -name '*.ipa' | head -n 1)"
fi
[ -n "$IPA" ] && [ -f "$IPA" ] || { echo "❌ No .ipa found — run ./build_ios.sh first, or pass --ipa <path>."; exit 1; }

for v in APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_ISSUER_ID; do
    [ -n "${!v:-}" ] || { echo "❌ Missing $v in .env.local"; exit 1; }
done

if ! resolve_asc_key; then
    echo "❌ App Store Connect API key not found at:"
    echo "   ${P8_FILE_PATH:-<unresolved>}"
    echo "   Download the .p8 from App Store Connect → Users and Access → Keys,"
    echo "   or set APP_STORE_CONNECT_KEY_DIR in .env.local."
    exit 1
fi

echo "Uploading $IPA ($(du -h "$IPA" | cut -f1)) to App Store Connect…"
xcrun altool --upload-app \
    --type ios \
    --file "$IPA" \
    --apiKey "$APP_STORE_CONNECT_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
    --apiKeyPath "$P8_FILE_PATH" || exit 1

echo
echo "✅ Uploaded. TestFlight processing usually takes 5-15 minutes."
