#!/bin/bash
# Builds a signed .ipa for App Store Connect. The iOS counterpart to
# build_android.sh — build only, no upload. Use scripts/upload_appstore.sh to
# ship the result, or ./deploy.sh to do the whole pipeline.
#
#   ./build_ios.sh                  # pods → flutter build → archive → export IPA
#   ./build_ios.sh --no-pods        # skip CocoaPods (faster re-builds)
#
# Like build_android.sh, this loads the RevenueCat keys from .env.local so a
# build can't silently ship with an empty key and a browse-only marketplace.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=scripts/lib/dotenv.sh
source scripts/lib/dotenv.sh
# shellcheck source=scripts/lib/ui.sh
source scripts/lib/ui.sh

RUN_PODS=true
for arg in "$@"; do
    case "$arg" in
        --no-pods) RUN_PODS=false ;;
        *) echo "unknown arg: $arg"; exit 1 ;;
    esac
done

[ -f .env.local ] || { echo "❌ Missing .env.local at project root."; exit 1; }
load_env_file .env.local
[ -f ios/ExportOptions.plist ] || { echo "❌ Missing ios/ExportOptions.plist (needed for -exportArchive)."; exit 1; }

if [ -z "${REVENUECAT_IOS_KEY:-}" ]; then
    echo "⚠️  REVENUECAT_IOS_KEY is empty — the IPA will ship with in-app"
    echo "   purchases disabled (marketplace falls back to browse-only)."
    echo
fi

echo "🍎 iOS release build"

if [ "$RUN_PODS" = true ]; then
    echo "  • CocoaPods install"
    (
        cd ios
        pod install >/tmp/spygame_pod_install.log 2>&1
        POD_STATUS=$?
        if [ $POD_STATUS -ne 0 ]; then
            echo "  ⚠️  pod install failed, retrying after 'pod repo update'..."
            pod repo update >/tmp/spygame_pod_repo_update.log 2>&1
            pod install >/tmp/spygame_pod_install_retry.log 2>&1
            POD_STATUS=$?
        fi
        if [ $POD_STATUS -ne 0 ]; then
            echo "❌ CocoaPods install failed. Logs:"
            echo "   /tmp/spygame_pod_install.log"
            echo "   /tmp/spygame_pod_repo_update.log"
            echo "   /tmp/spygame_pod_install_retry.log"
            exit 1
        fi
    ) || exit 1
    echo "  ✅ Pods installed"
fi

# Refreshes Generated.xcconfig with the current pubspec version — this is what
# fixes "Xcode archived the old version after I bumped pubspec".
# Only the iOS key is consumed at runtime here, but pass both so a missing
# variable surfaces at build time instead of crashing later.
run_with_spinner "Building Flutter for iOS (release)" \
    flutter build ios --release --no-codesign \
        --dart-define=REVENUECAT_IOS_KEY="${REVENUECAT_IOS_KEY:-}" \
        --dart-define=REVENUECAT_ANDROID_KEY="${REVENUECAT_ANDROID_KEY:-}"

run_with_spinner "Creating Xcode archive" \
    xcodebuild -workspace ios/Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -archivePath build/Runner.xcarchive \
        archive \
        -destination 'generic/platform=iOS' \
        -allowProvisioningUpdates

# Pass the App Store Connect API key to xcodebuild so automatic signing can
# create/download the Apple Distribution cert + provisioning profiles WITHOUT a
# logged-in Xcode account. Without these flags the export dies with "No
# Accounts / No signing certificate iOS Distribution found" on any machine
# where Xcode → Settings → Accounts is empty (e.g. CI, or after an Xcode/macOS
# update drops the account).
EXPORT_AUTH_FLAGS=()
if resolve_asc_key && [ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
    EXPORT_AUTH_FLAGS=(
        -authenticationKeyPath "$P8_FILE_PATH"
        -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID"
        -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID"
    )
    echo "  • Export will authenticate to App Store Connect via API key (no Xcode account needed)"
else
    echo "  ⚠️  No ASC API key resolved — export relies on a logged-in Xcode account"
fi

run_with_spinner "Exporting IPA" \
    env PATH="/usr/bin:$PATH" xcodebuild -exportArchive \
        -archivePath build/Runner.xcarchive \
        -exportPath build/ios \
        -exportOptionsPlist ios/ExportOptions.plist \
        -allowProvisioningUpdates \
        ${EXPORT_AUTH_FLAGS[@]+"${EXPORT_AUTH_FLAGS[@]}"}

# The IPA is named after CFBundleName, not PRODUCT_NAME, so we glob for it
# rather than hardcoding "Runner.ipa".
IPA_PATH="$(find build/ios -maxdepth 1 -type f -name '*.ipa' | head -n 1)"
if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
    echo "❌ No .ipa found in build/ios/ after export"
    ls -la build/ios/ || true
    exit 1
fi

echo
echo "✅ $IPA_PATH"
echo "   Upload with: scripts/upload_appstore.sh"
