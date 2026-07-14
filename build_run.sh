#!/usr/bin/env bash
#
# build_run.sh — generate, build, install, launch, and screenshot Enough on the
# iOS simulator, entirely from the CLI (no Xcode GUI). This is the command
# .harness/config/harness.env's VISUAL_VERIFY_HOOK points at.
#
# Usage: ./build_run.sh [simulator-name]   (default: "iPhone 17 Pro")

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Enough"
BUNDLE_ID="com.ryankrol.enough"
SIM_NAME="${1:-iPhone 17 Pro}"

# Resolve the argument to a concrete UDID. A device *name* can be ambiguous (the
# same model exists per installed runtime), so prefer an already-booted match,
# else the last (newest-runtime) available one. Pass a UDID to pin a specific
# simulator (e.g. to avoid clashing with another agent on a shared machine) —
# it's detected by shape and used as-is.
if [[ "$SIM_NAME" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}$ ]]; then
  SIM="$SIM_NAME"
else
  SIM_ID="$(xcrun simctl list devices booted | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | head -1 || true)"
  if [ -z "$SIM_ID" ]; then
    SIM_ID="$(xcrun simctl list devices available | grep -F "$SIM_NAME (" | grep -Eo '[0-9A-Fa-f-]{36}' | tail -1 || true)"
  fi
  SIM="${SIM_ID:-$SIM_NAME}"
fi

BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Debug-iphonesimulator/$APP_NAME.app"
SHOT_DIR="$PROJECT_DIR/screenshots"
SHOT_PATH="$SHOT_DIR/latest.png"

echo "▸ Generating Xcode project…"
xcodegen generate >/dev/null

echo "▸ Building $APP_NAME for the simulator…"
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -target "$APP_NAME" \
  -sdk iphonesimulator \
  -configuration Debug \
  build \
  SUPPORTED_PLATFORMS="iphonesimulator" \
  SYMROOT="$BUILD_DIR" \
  | tail -3

echo "▸ Booting simulator '$SIM_NAME'…"
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" >/dev/null 2>&1 || true
open -a Simulator || true

echo "▸ Installing + launching…"
xcrun simctl install "$SIM" "$APP_PATH"
xcrun simctl launch "$SIM" "$BUNDLE_ID"

mkdir -p "$SHOT_DIR"
sleep 3
xcrun simctl io "$SIM" screenshot "$SHOT_PATH" >/dev/null
echo "▸ Screenshot → $SHOT_PATH"
