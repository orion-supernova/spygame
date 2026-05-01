#!/usr/bin/env bash
set -euo pipefail

# Build Flutter web and inject the pubspec version into index.html
# so cache-busting query strings stay in sync with the app version.
#
# Usage:
#   ./scripts/build_web.sh           # build only
#   ./scripts/build_web.sh --deploy  # build and deploy to Firebase

cd "$(dirname "$0")/.."

VERSION=$(grep '^version:' pubspec.yaml | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

if [[ -z "$VERSION" ]]; then
  echo "Could not extract version from pubspec.yaml" >&2
  exit 1
fi

echo "Building web with version: $VERSION"
flutter build web

INDEX="build/web/index.html"
if [[ ! -f "$INDEX" ]]; then
  echo "Build output missing: $INDEX" >&2
  exit 1
fi

# Inject version into placeholders
sed -i '' "s/{{APP_VERSION}}/$VERSION/g" "$INDEX"

echo "Injected version $VERSION into $INDEX"

if [[ "${1:-}" == "--deploy" ]]; then
  firebase deploy --only hosting
fi
