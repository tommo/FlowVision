#!/usr/bin/env bash
# build_release.sh — build FlowVision Release and copy the .app to dist/
#
# Usage (from anywhere):
#   ./scripts/build_release.sh
#   ./scripts/build_release.sh --open      # open the app after build
#   ./scripts/build_release.sh --reveal    # reveal in Finder after build
#   ./scripts/build_release.sh --debug     # Debug configuration
#   CONFIGURATION=Debug ./scripts/build_release.sh
#
# Output (easy access):
#   <repo>/dist/FlowVision.app
#
# Dependencies (sibling dirs of the FlowVision repo, see README):
#   ../BTree
#   ../Settings
#   ../ffmpeg-kit-build/bundle-apple-xcframework-macos/

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${CONFIGURATION:-Release}"
OPEN_APP=0
REVEAL=0
SIGN=0
ONLY_ACTIVE_ARCH="${ONLY_ACTIVE_ARCH:-YES}"

for arg in "$@"; do
  case "$arg" in
    --open)   OPEN_APP=1 ;;
    --reveal) REVEAL=1 ;;
    --debug)  CONFIGURATION=Debug ;;
    --sign)   SIGN=1 ;;
    --universal)
      ONLY_ACTIVE_ARCH=NO
      ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

APP_NAME="FlowVision"
SCHEME="FlowVision"
PROJECT="FlowVision.xcodeproj"
DERIVED="$ROOT/build/DerivedData"
DIST="$ROOT/dist"
BUILT_APP="$DERIVED/Build/Products/$CONFIGURATION/${APP_NAME}.app"
DIST_APP="$DIST/${APP_NAME}.app"
SIBLING="$(cd "$ROOT/.." && pwd)"

echo "==> FlowVision build"
echo "    config:  $CONFIGURATION"
echo "    root:    $ROOT"
echo "    output:  $DIST_APP"
echo

# --- dependency checks ---
missing=0
for dep in BTree Settings; do
  if [[ ! -d "$SIBLING/$dep" ]]; then
    echo "!! Missing sibling package: $SIBLING/$dep" >&2
    missing=1
  fi
done
if [[ ! -d "$SIBLING/ffmpeg-kit-build/bundle-apple-xcframework-macos/ffmpegkit.xcframework" ]]; then
  echo "!! Missing ffmpeg-kit frameworks under:" >&2
  echo "   $SIBLING/ffmpeg-kit-build/bundle-apple-xcframework-macos/" >&2
  missing=1
fi
if [[ "$missing" -ne 0 ]]; then
  echo >&2
  echo "See README.md Build section for the expected sibling layout." >&2
  echo "Quick setup examples:" >&2
  echo "  git clone --depth 1 https://github.com/attaswift/BTree.git \"$SIBLING/BTree\"" >&2
  echo "  git clone --depth 1 https://github.com/sindresorhus/Settings.git \"$SIBLING/Settings\"" >&2
  exit 1
fi

# --- xcodebuild ---
mkdir -p "$DERIVED" "$DIST"

XCODEBUILD_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED"
  ONLY_ACTIVE_ARCH="$ONLY_ACTIVE_ARCH"
)

if [[ "$SIGN" -eq 0 ]]; then
  # Local/dev-friendly: no Mac Development certificate required
  XCODEBUILD_ARGS+=(
    CODE_SIGN_IDENTITY="-"
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGNING_ALLOWED=NO
    DEVELOPMENT_TEAM=""
  )
  echo "==> Building (unsigned / ad-hoc friendly)…"
else
  echo "==> Building (using project signing settings)…"
fi

xcodebuild "${XCODEBUILD_ARGS[@]}" build

if [[ ! -d "$BUILT_APP" ]]; then
  echo "!! Build finished but app not found at: $BUILT_APP" >&2
  exit 1
fi

# --- copy to dist/ ---
echo
echo "==> Copying to $DIST_APP"
rm -rf "$DIST_APP"
# ditto preserves resource forks / code attributes better than cp -R
ditto "$BUILT_APP" "$DIST_APP"

# Convenience symlink at repo root (optional, overwrite if present)
if [[ -L "$ROOT/${APP_NAME}.app" || ! -e "$ROOT/${APP_NAME}.app" ]]; then
  ln -sfn "dist/${APP_NAME}.app" "$ROOT/${APP_NAME}.app"
fi

# Symlink into /Applications for Launchpad / Spotlight access
APPS_LINK="/Applications/${APP_NAME}.app"
if ln -sfn "$DIST_APP" "$APPS_LINK" 2>/dev/null; then
  echo "==> Linked $APPS_LINK -> $DIST_APP"
elif [[ -e "$APPS_LINK" || -L "$APPS_LINK" ]]; then
  echo "!! Could not update $APPS_LINK (permission or existing item). Run:"
  echo "   sudo ln -sfn \"$DIST_APP\" \"$APPS_LINK\""
else
  echo "!! Could not create $APPS_LINK. Run:"
  echo "   sudo ln -sfn \"$DIST_APP\" \"$APPS_LINK\""
fi

echo
echo "** BUILD OK **"
echo "App path:"
echo "  $DIST_APP"
echo "  $APPS_LINK  (symlink)"
ls -lh "$DIST_APP/Contents/MacOS/$APP_NAME" 2>/dev/null || true
du -sh "$DIST_APP" || true

if [[ "$REVEAL" -eq 1 ]]; then
  open -R "$DIST_APP"
fi
if [[ "$OPEN_APP" -eq 1 ]]; then
  open "$DIST_APP"
fi
