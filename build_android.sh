#!/bin/bash
# Builds the release Android App Bundle for Google Play, loading the
# RevenueCat SDK keys from .env.local the same way run.sh and deploy.sh do.
#
# A plain `flutter build appbundle --release` compiles fine but bakes in an
# EMPTY RevenueCat key, which silently drops the marketplace into browse-only
# mode (no Buy / Restore) — see RevenueCatBootstrap.initialize(). Always ship
# through this script.
#
#   ./build_android.sh              # signed .aab for Play upload
#   ./build_android.sh --apk        # signed .apk for direct sideloading
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# Same minimal extractor as run.sh — these keys are plain alphanumerics.
extract() {
    grep -E "^[[:space:]]*${1}=" .env.local 2>/dev/null \
        | head -n 1 \
        | sed -E "s/^[[:space:]]*${1}=//; s/^['\"]//; s/['\"]\$//"
}

REVENUECAT_IOS_KEY=$(extract REVENUECAT_IOS_KEY)
REVENUECAT_ANDROID_KEY=$(extract REVENUECAT_ANDROID_KEY)

if [ ! -f android/key.properties ]; then
    echo "❌ android/key.properties missing — the build would be signed with the"
    echo "   debug key and Google Play would reject it. See your private deploy notes."
    exit 1
fi

if [ -z "$REVENUECAT_ANDROID_KEY" ]; then
    echo "⚠️  REVENUECAT_ANDROID_KEY is empty in .env.local."
    echo "   The build will succeed, but in-app purchases will NOT work on Android"
    echo "   (marketplace falls back to browse-only). Fine for the very first Play"
    echo "   upload; fill the goog_ key from RevenueCat before any real release."
    echo
fi

TARGET="appbundle"
EXTRA=()
for arg in "$@"; do
    case "$arg" in
        --apk) TARGET="apk" ;;
        *) EXTRA+=("$arg") ;;
    esac
done

set -e
flutter build "$TARGET" --release \
    --dart-define=REVENUECAT_IOS_KEY="$REVENUECAT_IOS_KEY" \
    --dart-define=REVENUECAT_ANDROID_KEY="$REVENUECAT_ANDROID_KEY" \
    ${EXTRA[@]+"${EXTRA[@]}"}

if [ "$TARGET" = "appbundle" ]; then
    OUT="build/app/outputs/bundle/release/app-release.aab"
else
    OUT="build/app/outputs/flutter-apk/app-release.apk"
fi

echo
echo "✅ $OUT"
echo "   Signed by:"
keytool -printcert -jarfile "$OUT" 2>/dev/null | grep -E "^Owner:" | head -1 | sed 's/^/     /'
