#!/bin/bash
# Wrapper around `flutter run` that auto-loads RevenueCat (and any other
# build-time) keys from .env.local so you don't have to remember the
# --dart-define flags. Forwards any extra args straight to flutter run.
#
#   ./run.sh                       # default device
#   ./run.sh -d chrome             # web target (RC falls back to browse-only)
#   ./run.sh -d "iPhone 16"        # specific simulator
#   ./run.sh --release             # release-mode local run
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# Pull a single key out of .env.local, tolerant of whitespace and quotes.
# Stays minimal on purpose — keys here are simple alphanumerics; the
# heavier loader in deploy.sh is only needed for values with shell
# metacharacters like the Convex admin key.
extract() {
    grep -E "^[[:space:]]*${1}=" .env.local 2>/dev/null \
        | head -n 1 \
        | sed -E "s/^[[:space:]]*${1}=//; s/^['\"]//; s/['\"]$//"
}

REVENUECAT_IOS_KEY=$(extract REVENUECAT_IOS_KEY)
REVENUECAT_ANDROID_KEY=$(extract REVENUECAT_ANDROID_KEY)

if [ -z "$REVENUECAT_IOS_KEY" ] && [ -z "$REVENUECAT_ANDROID_KEY" ]; then
    echo "ℹ️  RevenueCat keys not set in .env.local — marketplace will run in browse-only mode."
fi

exec flutter run \
    --dart-define=REVENUECAT_IOS_KEY="$REVENUECAT_IOS_KEY" \
    --dart-define=REVENUECAT_ANDROID_KEY="$REVENUECAT_ANDROID_KEY" \
    "$@"
