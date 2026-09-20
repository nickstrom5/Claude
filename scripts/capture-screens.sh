#!/bin/bash
# Build Clam for a simulator, run the unit tests there, and capture every screen.
#
#   scripts/capture-screens.sh                              # iPhone Duo, inner display
#   scripts/capture-screens.sh --pose closed --no-tests     # fold it first, then the outer display
#   scripts/capture-screens.sh --device "iPhone 18"         # QA on a regular iPhone
#   scripts/capture-screens.sh --list                       # what simulators are available
#
# Captures go to docs/screenshots/<slug>/ (duo, iphone-18, ...) plus small-* thumbnails.
# A blank capture is detected with sips alone (no Pillow), retried on the device's other
# display, then relaunched; if it still fails the app's log is printed.
# CI runs this with --ci (screenshots.yml, "duo" job) once the runner image ships Xcode 27.
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE_NAME="iPhone Duo"; POSE=open; RUN_TESTS=1; CI_MODE=0; OUT=""; LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --device) DEVICE_NAME="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --pose) POSE="$2"; shift 2 ;;
    --no-tests) RUN_TESTS=0; shift ;;
    --ci) CI_MODE=1; RUN_TESTS=0; shift ;;
    --list) LIST=1; shift ;;
    *) echo "unknown option $1"; exit 2 ;;
  esac
done

# 1. Xcode 27+ (the Duo needs it; any recent Xcode works for other devices).
pick_xcode() {
  local cand v
  for cand in "${DEVELOPER_DIR:-}" "$(xcode-select -p 2>/dev/null | sed 's#/Contents/Developer##')" \
              /Applications/Xcode-beta.app $(ls -d /Applications/Xcode_27*.app 2>/dev/null | sort -V) ; do
    [ -n "$cand" ] && [ -d "$cand" ] || continue
    cand="${cand%/Contents/Developer}"
    v=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$cand/Contents/Info.plist" 2>/dev/null || echo 0)
    if [ "${v%%.*}" -ge 27 ]; then echo "$cand/Contents/Developer"; return; fi
  done
}
export DEVELOPER_DIR="$(pick_xcode)"
if [ -z "$DEVELOPER_DIR" ]; then
  echo "Xcode 27.1 or newer not found. Install it from developer.apple.com/download, then rerun."; exit 1
fi
echo "Using $(xcodebuild -version | head -1)"

if [ "$LIST" = 1 ]; then
  echo; echo "Runtimes:"; xcrun simctl list runtimes available | tail -n +2
  echo; echo "Devices:"; xcrun simctl list devices available | grep -E "iPhone|iPad" || true
  exit 0
fi

# 2. Runtime + device. Both are created on first run if missing.
RT=$(xcrun simctl list runtimes available | grep -E "iOS 27" | tail -1 | sed -E 's/.* - (com\.apple[^ ]+).*/\1/' || true)
if [ -z "$RT" ]; then
  echo "No iOS 27 simulator runtime installed yet. Installed runtimes:"; xcrun simctl list runtimes available | tail -n +2
  echo "Install it in Xcode > Settings > Components, then rerun."; exit 1
fi
DEVICE=$(xcrun simctl list devices available | grep -E "^ *${DEVICE_NAME} \(" | head -1 | sed -E 's/^ *(.+) \([0-9A-F-]+\) \(.*/\1/' || true)
if [ -z "$DEVICE" ]; then
  TYPE="com.apple.CoreSimulator.SimDeviceType.$(echo "$DEVICE_NAME" | tr ' ' '-')"
  if ! xcrun simctl create "$DEVICE_NAME" "$TYPE" "$RT" >/dev/null 2>&1; then
    echo "No simulator named '$DEVICE_NAME' and it could not be created."
    echo "Available devices:"; xcrun simctl list devices available | grep -E "iPhone" || true
    exit 1
  fi
  DEVICE="$DEVICE_NAME"
fi
SLUG=$(echo "$DEVICE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'); [ "$SLUG" = "iphone-duo" ] && SLUG=duo
[ -n "$OUT" ] || OUT="docs/screenshots/$SLUG"
echo "Simulator: $DEVICE ($RT) -> $OUT"

# 3. Generate, build, test.
command -v xcodegen >/dev/null || { echo "brew install xcodegen first"; exit 1; }
xcodegen generate >/dev/null
DEST="platform=iOS Simulator,name=$DEVICE"
set -o pipefail
xcodebuild build -project Clam.xcodeproj -scheme Clam -destination "$DEST" -derivedDataPath DerivedData \
  -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO 2>&1 | tee capture-build.log | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
grep -q "BUILD SUCCEEDED" capture-build.log || { echo "Build failed, see capture-build.log"; exit 1; }
if [ "$RUN_TESTS" = 1 ]; then
  xcodebuild test -project Clam.xcodeproj -scheme Clam -destination "$DEST" -derivedDataPath DerivedData \
    -only-testing:ClamTests -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO 2>&1 | tee capture-test.log \
    | grep -E "error:|Test Case .* failed|TEST (SUCCEEDED|FAILED)|Executed" || true
  grep -q "TEST SUCCEEDED" capture-test.log || { echo "Tests failed, see capture-test.log"; exit 1; }
fi

# 4. Boot, install.
xcrun simctl boot "$DEVICE" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null
[ "$CI_MODE" = 1 ] || open -a Simulator >/dev/null 2>&1 || true
xcrun simctl ui "$DEVICE" appearance dark >/dev/null 2>&1 || true
APP=$(find DerivedData/Build/Products -name "Clam.app" -maxdepth 2 | head -1)
xcrun simctl install "$DEVICE" "$APP"
sleep 3

# The Duo's unlit display captures as pure black, so the simulator has to be in the pose
# we are capturing before we start. The open pose needs it unfolded, which is easy to forget
# straight after a closed run.
if [ "$CI_MODE" = 0 ] && [ "$DEVICE" = "iPhone Duo" ]; then
  echo
  if [ "$POSE" = closed ]; then
    echo "Fold the simulator now (Simulator app > Device menu, or the pose control on the window)."
    read -r -p "Press Return when the outer display is showing... " _
  else
    echo "Unfold the simulator now (Simulator app > Device menu) so the inner display is lit."
    read -r -p "Press Return when the big inner display is showing... " _
  fi
fi

mkdir -p "$OUT"
PREFIX=""; [ "$POSE" = open ] || PREFIX="$POSE-"
SCREENS="hook hours apps triggers reveal permission taste result paywall home session settings share"
[ "$CI_MODE" = 1 ] && SCREENS="home session paywall reveal share"

# Is this capture a blank frame? Pillow gives a real brightness reading; where it is missing
# (a stock Mac) fall back on file size, because a black PNG compresses to a few KB while a real
# screenshot of these displays is hundreds. Never guess "fine" when we cannot tell.
looks_blank() {
  local f="$1" mean
  [ -s "$f" ] || return 0
  mean=$(python3 - "$f" 2>/dev/null <<'PYEOF'
import sys
from PIL import Image, ImageStat
print(int(ImageStat.Stat(Image.open(sys.argv[1]).convert("L")).mean[0]))
PYEOF
)
  if [ -n "$mean" ]; then
    [ "$mean" -le 6 ]
  else
    [ "$(stat -f%z "$f" 2>/dev/null || echo 0)" -lt 40000 ]
  fi
}

# The Duo has two displays and only one is lit in a pose; simctl's default is not reliably
# the lit one (it changes after `simctl erase`), so find it once and reuse it.
pick_display() {
  local d probe
  probe="${TMPDIR:-/tmp}/clam-probe-$$.png"
  for d in primary internal external; do
    if xcrun simctl io "$DEVICE" screenshot --display "$d" "$probe" >/dev/null 2>&1; then
      if ! looks_blank "$probe"; then rm -f "$probe"; echo "--display $d"; return; fi
    fi
  done
  rm -f "$probe"; echo "dark"
}
DISPLAY_ARG=$(pick_display)
if [ "$DISPLAY_ARG" = dark ]; then
  echo
  echo "Every display on $DEVICE is dark, so any capture would be a black frame."
  echo "On a Duo that usually means the simulator is in the other pose: this run wants the"
  echo "$([ "$POSE" = closed ] && echo "outer" || echo "inner") display lit. Change the pose and rerun."
  exit 1
fi
echo "Capturing with $DISPLAY_ARG"

FAILED=""; PREV_SUM=""
for s in $SCREENS; do
  f="$OUT/$PREFIX$s.png"; ok=0; sum=""
  for attempt in 1 2 3; do
    xcrun simctl terminate "$DEVICE" app.getclam.clam >/dev/null 2>&1 || true; sleep 1
    PID=$(xcrun simctl launch "$DEVICE" app.getclam.clam -screenshot "$s" 2>&1 | sed -E 's/.*: *//')
    sleep 8
    if ! xcrun simctl spawn "$DEVICE" launchctl list 2>/dev/null | grep -q "app.getclam.clam"; then
      echo "  $s: app is not running after launch (pid was ${PID:-?})"
    fi
    # shellcheck disable=SC2086
    xcrun simctl io "$DEVICE" screenshot $DISPLAY_ARG "$f" >/dev/null 2>&1 || true
    sum=$(md5 -q "$f" 2>/dev/null || echo none)
    if looks_blank "$f"; then
      echo "  $s: blank frame, relaunching ($attempt/3)"
    elif [ -n "$PREV_SUM" ] && [ "$sum" = "$PREV_SUM" ]; then
      echo "  $s: same frame as the previous screen, waiting and retrying ($attempt/3)"
      sleep 5
    else
      ok=1; break
    fi
  done
  if [ "$ok" = 1 ]; then
    PREV_SUM="$sum"
    echo "captured $f ($(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/ {printf "%s ", $2}'))"
  else
    FAILED="$FAILED $s"; echo "FAILED $f"
  fi
done

if [ -n "$FAILED" ]; then
  echo; echo "Blank screens:$FAILED"
  echo "--- last 40 log lines from the app ---"
  xcrun simctl spawn "$DEVICE" log show --last 3m --predicate 'process == "Clam"' 2>/dev/null | tail -40 || true
  echo "--- displays simctl reports ---"; xcrun simctl io "$DEVICE" enumerate 2>/dev/null | grep -iE "display|port" | head -20 || true
  rm -f capture-build.log capture-test.log
  exit 1
fi

for f in "$OUT"/"$PREFIX"*.png; do
  case "$(basename "$f")" in small-*) continue ;; esac
  sips -Z 700 "$f" --out "$OUT/small-$(basename "$f")" >/dev/null
done
rm -f capture-build.log capture-test.log

echo; echo "Done: $OUT/$PREFIX*.png"
if [ "$POSE" = open ] && [ "$CI_MODE" = 0 ]; then
  echo "Commit: git add $OUT && git commit -m 'Simulator screenshots: $DEVICE' && git push"
fi
