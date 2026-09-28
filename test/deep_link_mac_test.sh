#!/usr/bin/env bash
# Deep links on macOS, against the built app: a link opened from outside
# brings the app to the page it names, whether the app was running or not.
#
# The system only sends a scheme to an app bundle it has been told about, so
# this needs the app built: bin/demo-package. It is registered from where it
# was built; nothing is copied into /Applications.
#
#   test/deep_link_mac_test.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="task-manager"
BUNDLE_ID="com.task-manager.app"
PORT="${PORT:-3000}"
LOG="log/development.log"
REGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
failures=0

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

[ "$(uname)" = "Darwin" ] || { echo "SKIP: this is the macOS test"; exit 0; }

APP="$(find desktop/src-tauri/target -maxdepth 6 -path "*release/bundle/macos/*.app" -prune 2>/dev/null | head -n 1)"
if [ -z "$APP" ]; then
  echo "No built app. Run bin/demo-package first."
  exit 2
fi
APP="$ROOT/$APP"
echo "App: $APP"

running() { pgrep -f "$APP/Contents/MacOS/" >/dev/null 2>&1; }
quit() {
  osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1
  for _ in $(seq 1 20); do running || return 0; sleep 0.5; done
  return 1
}

# Wait for the server to be asked for a path, by a request made after `since`.
asked_for() {
  local path="$1" since="$2"
  for _ in $(seq 1 90); do
    if tail -n +"$((since + 1))" "$LOG" 2>/dev/null | grep -q "Started GET \"$path\""; then
      return 0
    fi
    sleep 1
  done
  return 1
}

# The scheme has to be in the bundle for the system to send it here at all.
if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes" "$APP/Contents/Info.plist" 2>/dev/null | grep -q "$SCHEME"; then
  pass "the built app declares the $SCHEME:// scheme"
else
  fail "the built app does not declare the $SCHEME:// scheme"
fi

"$REGISTER" -f "$APP"
touch "$LOG"

# ── 1. The app is not running: the link starts it ────────────────────────────
quit || fail "could not quit the app before the test"
since="$(wc -l < "$LOG")"
open "$SCHEME://checks?from=deep-link&case=cold"

if asked_for "/checks?from=deep-link&case=cold" "$since"; then
  pass "a link opened with the app closed starts it on the page the link names"
else
  fail "the app did not visit /checks?from=deep-link&case=cold after a cold start"
fi
running || fail "the link did not start the app"

# ── 2. The app is running: the link goes to the window that is open ──────────
since="$(wc -l < "$LOG")"
open "$SCHEME://tasks?from=deep-link&case=running"

if asked_for "/tasks?from=deep-link&case=running" "$since"; then
  pass "a link opened with the app running takes it to the page the link names"
else
  fail "the app did not visit /tasks?from=deep-link&case=running while running"
fi

# ── 3. A link cannot take the app somewhere else ─────────────────────────────
since="$(wc -l < "$LOG")"
open "$SCHEME://evil.example.com@localhost:$PORT/checks?from=deep-link&case=elsewhere" 2>/dev/null
open "$SCHEME:////evil.example.com/checks?from=deep-link&case=elsewhere" 2>/dev/null
sleep 4
if tail -n +"$((since + 1))" "$LOG" | grep -q "evil.example.com"; then
  fail "a link took the app outside itself"
else
  pass "a link that names another host is not followed there"
fi

quit || fail "the app did not quit"
sleep 2
if running; then fail "the app is still running"; else pass "the app quits when asked"; fi

echo
[ "$failures" -eq 0 ] && echo "all passed" || echo "$failures failed"
exit "$failures"
