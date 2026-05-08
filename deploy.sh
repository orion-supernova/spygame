#!/bin/bash
# Spygame deploy script (iOS + web).
#
# Default behavior: deploy Convex backend → flutter clean/get/codegen → bump pubspec
# version → pod install → flutter build iOS → xcodebuild archive + export → upload to
# App Store Connect → flutter build web + firebase hosting deploy → commit + push the
# version bump.
#
# Run-and-ship: ./deploy.sh
# See ./deploy.sh -h for flags.

set -uo pipefail

SCRIPT_START_TIME=$(date +%s)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ----- flags -----
SKIP_VERSION_BUMP=false
RUN_CONVEX=true
RUN_IOS=true
RUN_UPLOAD=true
RUN_WEB=true
RUN_GIT=true
DRY_RUN=false
TARGET_FLAG_PROVIDED=false

print_help() {
    cat <<EOF
Usage: ./deploy.sh [flags]

Default (no flags, TTY): prompts you to pick iOS / Web / All. With no TTY (CI),
defaults to a full ship — Convex deploy + version bump + iOS build + ASC upload
+ web build + Firebase hosting deploy + git push.

Any of --no-ios / --no-web / --no-upload / --dry counts as a target choice and
skips the prompt.

Flags:
  --skip-version-bump   Re-ship the same version (e.g. after fixing a build issue).
  --no-convex           Skip 'npx convex deploy'.
  --no-ios              Skip the iOS build + ASC upload entirely.
  --no-upload           Archive + export the IPA but do NOT upload to App Store Connect.
  --no-web              Skip the Flutter web build + Firebase hosting deploy.
  --no-git              Don't commit/push the version bump.
  --dry                 Same as --no-convex --no-upload --no-web --no-git --skip-version-bump.
                        Use this to test the build path end-to-end without side effects.
  -h, --help            Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-version-bump) SKIP_VERSION_BUMP=true ;;
        --no-convex)         RUN_CONVEX=false ;;
        --no-ios)            RUN_IOS=false; RUN_UPLOAD=false; TARGET_FLAG_PROVIDED=true ;;
        --no-upload)         RUN_UPLOAD=false; TARGET_FLAG_PROVIDED=true ;;
        --no-web)            RUN_WEB=false; TARGET_FLAG_PROVIDED=true ;;
        --no-git)            RUN_GIT=false ;;
        --dry)
            DRY_RUN=true
            RUN_CONVEX=false
            RUN_UPLOAD=false
            RUN_WEB=false
            RUN_GIT=false
            SKIP_VERSION_BUMP=true
            TARGET_FLAG_PROVIDED=true
            ;;
        -h|--help) print_help; exit 0 ;;
        *) echo "❌ Unknown flag: $1"; print_help; exit 1 ;;
    esac
    shift
done

# ----- target selection prompt -----
# When invoked interactively with no target flag, ask which surface(s) to ship.
# CI/non-TTY runs fall through to today's defaults (full ship).
if [ "$TARGET_FLAG_PROVIDED" = false ] && [ -t 0 ]; then
    echo "What do you want to deploy?"
    echo "  1) iOS only"
    echo "  2) Web only"
    echo "  3) All (iOS + Web)  [default]"
    printf "Choose [1/2/3]: "
    read -r TARGET_CHOICE </dev/tty
    case "$TARGET_CHOICE" in
        1) RUN_IOS=true;  RUN_WEB=false ;;
        2) RUN_IOS=false; RUN_UPLOAD=false; RUN_WEB=true ;;
        ""|3) ;;  # all: keep defaults
        *) echo "❌ Invalid choice: $TARGET_CHOICE"; exit 1 ;;
    esac
    echo ""
fi

echo "🚀 Spygame deploy"
echo "  • Convex deploy:    $([ "$RUN_CONVEX" = true ] && echo yes || echo no)"
echo "  • Version bump:     $([ "$SKIP_VERSION_BUMP" = false ] && echo yes || echo no)"
echo "  • iOS build:        $([ "$RUN_IOS" = true ] && echo yes || echo no)"
echo "  • Upload to ASC:    $([ "$RUN_UPLOAD" = true ] && echo yes || echo no)"
echo "  • Web (Firebase):   $([ "$RUN_WEB" = true ] && echo yes || echo no)"
echo "  • Git commit/push:  $([ "$RUN_GIT" = true ] && echo yes || echo no)"
[ "$DRY_RUN" = true ] && echo "  • Mode: DRY (no side effects)"
echo ""

# ----- spinner helpers -----
function finish { tput cnorm 2>/dev/null || true; }
trap finish EXIT

spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='|/-\'
    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 $((${#spinstr} - 1))); do
            tput sc 2>/dev/null
            tput cup $(($(tput lines) - 1)) 0 2>/dev/null
            printf "%s %s" "${spinstr:$i:1}" "$message"
            tput rc 2>/dev/null
            sleep "$delay"
        done
    done
    tput sc 2>/dev/null
    tput cup $(($(tput lines) - 1)) 0 2>/dev/null
    printf "   %s\n" "$message"
    tput rc 2>/dev/null
    tput cnorm 2>/dev/null || true
}

run_with_spinner() {
    local description="$1"
    shift
    echo "$description..."
    "$@" &
    local pid=$!
    spinner "$pid" "$description"
    wait "$pid"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "  ✅ $description"
    else
        echo "  ❌ $description failed (exit $exit_code)"
        exit $exit_code
    fi
}

# Load a dotenv file into the environment without running values through bash
# command interpretation. `source .env.local` chokes on values containing
# unquoted '|', '&', ';', '$()' etc. — common in keys/secrets. This loader:
#   - skips blanks and # comments
#   - strips matched surrounding "..." or '...'
#   - expands $VAR / ${VAR} / ${VAR:-default} (so $HOME paths still work)
#   - neutralizes command substitution and backticks
load_env_file() {
    local file="$1"
    [ -f "$file" ] || return 1
    local line key value stripped first last safe
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        stripped="${line#"${line%%[![:space:]]*}"}"
        [ -z "$stripped" ] && continue
        [ "${stripped:0:1}" = "#" ] && continue
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        key="${key//[[:space:]]/}"
        key="${key#export}"
        [ -z "$key" ] && continue
        if [ ${#value} -ge 2 ]; then
            first="${value:0:1}"
            last="${value: -1}"
            if { [ "$first" = '"' ] && [ "$last" = '"' ]; } || \
               { [ "$first" = "'" ] && [ "$last" = "'" ]; }; then
                value="${value:1:${#value}-2}"
            fi
        fi
        safe="${value//\\/\\\\}"
        safe="${safe//\"/\\\"}"
        safe="${safe//\`/\\\`}"
        safe="${safe//\$(/\\\$(}"
        eval "value=\"$safe\""
        export "$key=$value"
    done < "$file"
}

# ----- environment validation -----
validate_environment() {
    echo "🔐 Validating environment..."

    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "❌ deploy.sh is iOS-only and must run on macOS."
        exit 1
    fi

    if [ ! -f ".env.local" ]; then
        echo "❌ Missing .env.local at project root."
        echo "   Copy .env.local.example to .env.local and fill in values."
        exit 1
    fi

    load_env_file .env.local

    check_key() {
        local key_name=$1
        local key_value=${!key_name:-}
        if [ -z "$key_value" ]; then
            echo "❌ Missing $key_name in .env.local"
            exit 1
        fi
        if [[ "$key_value" == *"replace-with-"* ]] || [[ "$key_value" == *"your_"*"_here"* ]]; then
            echo "❌ $key_name still has a placeholder value in .env.local"
            exit 1
        fi
    }

    if [ "$RUN_CONVEX" = true ]; then
        check_key CONVEX_SELF_HOSTED_URL
        check_key CONVEX_SELF_HOSTED_ADMIN_KEY
    fi

    if [ "$RUN_UPLOAD" = true ]; then
        check_key APP_STORE_CONNECT_KEY_ID
        check_key APP_STORE_CONNECT_ISSUER_ID

        # Directory holding the .p8. Override APP_STORE_CONNECT_KEY_DIR in
        # .env.local if your key isn't at the default path (e.g. when juggling
        # keys across multiple Apple Developer teams).
        local key_dir="${APP_STORE_CONNECT_KEY_DIR:-$HOME/.appstoreconnect/private_keys}"
        P8_FILE_PATH="$key_dir/AuthKey_$APP_STORE_CONNECT_KEY_ID.p8"
        if [ ! -f "$P8_FILE_PATH" ]; then
            echo "❌ App Store Connect API key not found at:"
            echo "   $P8_FILE_PATH"
            echo "   Download the .p8 from App Store Connect → Users and Access → Keys"
            echo "   and place it there, or set APP_STORE_CONNECT_KEY_DIR in .env.local."
            exit 1
        fi
    fi

    if [ "$RUN_IOS" = true ] && [ ! -f "ios/ExportOptions.plist" ]; then
        echo "❌ Missing ios/ExportOptions.plist (needed for xcodebuild -exportArchive)."
        exit 1
    fi

    if [ "$RUN_WEB" = true ]; then
        if ! command -v firebase >/dev/null 2>&1; then
            echo "❌ firebase CLI not found on PATH."
            echo "   Install with: npm i -g firebase-tools  (then 'firebase login')"
            exit 1
        fi
        if [ ! -f "firebase.json" ] || [ ! -f ".firebaserc" ]; then
            echo "❌ Missing firebase.json or .firebaserc at project root."
            exit 1
        fi
    fi

    echo "  ✅ Environment OK"
}

validate_environment

# ----- Convex deploy -----
if [ "$RUN_CONVEX" = true ]; then
    # IMPORTANT: must run from project root, NOT from convex/ — running from inside
    # convex/ creates a nested convex/convex/ and silently deploys nothing.
    run_with_spinner "Deploying Convex backend" npx convex deploy
fi

# ----- Flutter prep -----
run_with_spinner "Flutter clean" flutter clean
run_with_spinner "Flutter pub get" flutter pub get
run_with_spinner "Running build_runner (freezed/riverpod/json_serializable)" \
    dart run build_runner build --delete-conflicting-outputs

# ----- Version bump -----
NEW_VERSION=""
if [ "$SKIP_VERSION_BUMP" = false ]; then
    echo "📝 Bumping version..."
    VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
    echo "  • Current: $VERSION"

    MAJOR=$(echo "$VERSION" | cut -d. -f1)
    MINOR=$(echo "$VERSION" | cut -d. -f2)
    PATCH=$(echo "$VERSION" | cut -d. -f3 | cut -d+ -f1)
    BUILD=$(echo "$VERSION" | cut -d+ -f2)

    NEW_PATCH=$((PATCH + 1))
    NEW_BUILD=$((BUILD + 1))
    NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH+$NEW_BUILD"

    echo "  • New:     $NEW_VERSION"
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
    echo "  ✅ pubspec.yaml updated"
else
    NEW_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
    echo "⏭️  Skipping version bump — using $NEW_VERSION"
fi

# ----- iOS build -----
IOS_BUILD_TIME=0
IPA_PATH=""
IOS_SUCCESS=false
if [ "$RUN_IOS" = true ]; then
    IOS_START_TIME=$(date +%s)
    echo "🍎 Starting iOS build..."

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
    )
    echo "  ✅ Pods installed"

    # Refreshes Generated.xcconfig with the current pubspec version — this is what
    # fixes "Xcode archived the old version after I bumped pubspec".
    run_with_spinner "Building Flutter for iOS (release)" \
        flutter build ios --release --no-codesign

    run_with_spinner "Creating Xcode archive" \
        xcodebuild -workspace ios/Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -archivePath build/Runner.xcarchive \
            archive \
            -destination 'generic/platform=iOS' \
            -allowProvisioningUpdates

    run_with_spinner "Exporting IPA" \
        env PATH="/usr/bin:$PATH" xcodebuild -exportArchive \
            -archivePath build/Runner.xcarchive \
            -exportPath build/ios \
            -exportOptionsPlist ios/ExportOptions.plist \
            -allowProvisioningUpdates

    # The IPA is named after CFBundleName, not PRODUCT_NAME, so we glob for it
    # rather than hardcoding "Runner.ipa".
    IPA_PATH="$(find build/ios -maxdepth 1 -type f -name '*.ipa' | head -n 1)"
    if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
        echo "❌ No .ipa found in build/ios/ after export"
        ls -la build/ios/ || true
        exit 1
    fi
    echo "  ✅ IPA at $IPA_PATH"

    # ----- Upload -----
    if [ "$RUN_UPLOAD" = true ]; then
        run_with_spinner "Uploading to App Store Connect" \
            xcrun altool --upload-app \
                --type ios \
                --file "$IPA_PATH" \
                --apiKey "$APP_STORE_CONNECT_KEY_ID" \
                --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
                --apiKeyPath "$P8_FILE_PATH"
        IOS_SUCCESS=true
    else
        echo "⏭️  Skipping App Store Connect upload (--no-upload)"
        IOS_SUCCESS=true
    fi

    IOS_END_TIME=$(date +%s)
    IOS_BUILD_TIME=$((IOS_END_TIME - IOS_START_TIME))
else
    echo "⏭️  Skipping iOS build (--no-ios)"
fi

# ----- Web build + Firebase deploy -----
WEB_BUILD_TIME=0
WEB_SUCCESS=false
if [ "$RUN_WEB" = true ]; then
    WEB_START_TIME=$(date +%s)
    echo "🌐 Starting web build..."

    run_with_spinner "Building Flutter for web" flutter build web

    # Cache-bust query strings in index.html reference {{APP_VERSION}}; the
    # major.minor.patch from pubspec replaces them so the deployed HTML pulls
    # fresh JS/assets after each ship.
    WEB_VERSION=$(echo "$NEW_VERSION" | cut -d+ -f1)
    INDEX="build/web/index.html"
    if [ ! -f "$INDEX" ]; then
        echo "❌ Build output missing: $INDEX"
        exit 1
    fi
    sed -i '' "s/{{APP_VERSION}}/$WEB_VERSION/g" "$INDEX"
    echo "  ✅ Injected version $WEB_VERSION into $INDEX"

    run_with_spinner "Deploying to Firebase hosting" \
        firebase deploy --only hosting --non-interactive

    WEB_END_TIME=$(date +%s)
    WEB_BUILD_TIME=$((WEB_END_TIME - WEB_START_TIME))
    WEB_SUCCESS=true
else
    echo "⏭️  Skipping web build + Firebase deploy (--no-web)"
fi

# ----- Git -----
if [ "$RUN_GIT" = true ] && [ "$SKIP_VERSION_BUMP" = false ]; then
    echo "🔄 Git commit + push..."
    if [ -n "$(git status --porcelain pubspec.yaml)" ]; then
        git add pubspec.yaml
        git commit -m "chore: bump version to $NEW_VERSION"
        CURRENT_BRANCH=$(git branch --show-current)
        echo "  • Pushing to origin/$CURRENT_BRANCH..."
        if git push origin "$CURRENT_BRANCH"; then
            echo "  ✅ Pushed"
        else
            echo "  ⚠️  git push failed. Commit is local; push manually with:"
            echo "       git push origin $CURRENT_BRANCH"
        fi
    else
        echo "  • pubspec.yaml has no staged changes, nothing to commit"
    fi
elif [ "$RUN_GIT" = false ]; then
    echo "⏭️  Skipping git commit/push (--no-git)"
fi

# ----- Summary -----
SCRIPT_END_TIME=$(date +%s)
TOTAL_TIME=$((SCRIPT_END_TIME - SCRIPT_START_TIME))

echo ""
echo "✨ Deploy complete"
echo "  📱 Version:        $NEW_VERSION"
if [ "$RUN_IOS" = true ]; then
    [ "$RUN_UPLOAD" = true ] && echo "  🍎 Uploaded to:    App Store Connect (TestFlight will show the build in a few minutes)"
    [ "$RUN_UPLOAD" = false ] && echo "  📦 IPA available:  $IPA_PATH"
fi
[ "$WEB_SUCCESS" = true ] && echo "  🌐 Web deployed:   Firebase hosting"
echo ""
echo "⏱️  Timing:"
[ "$RUN_IOS" = true ] && echo "  🍎 iOS build:      ${IOS_BUILD_TIME}s"
[ "$RUN_WEB" = true ] && echo "  🌐 Web build:      ${WEB_BUILD_TIME}s"
echo "  📊 Total:          ${TOTAL_TIME}s"
