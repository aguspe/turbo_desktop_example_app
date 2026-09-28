#!/usr/bin/env bash
# Opening a file with the app on macOS, against the built app: the file is
# read and its tasks imported, whether the app was running or not, and the
# file's path is never asked of the server as though it were a page.
#
# Needs the app built: bin/demo-package.
#
#   test/file_open_mac_test.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUNDLE_ID="com.task-manager.app"
LOG="log/development.log"
failures=0

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

[ "$(uname)" = "Darwin" ] || { echo "SKIP: this is the macOS test"; exit 0; }

APP="$(find desktop/src-tauri/target -maxdepth 6 -path "*release/bundle/macos/*.app" -prune 2>/dev/null | head -n 1)"
if [ -z "$APP" ]; then
  echo "No built app. Run bin/demo-package first."
  exit 2
fi
echo "App: $APP"

running() { pgrep -f "$APP/Contents/MacOS/" >/dev/null 2>&1; }
quit() {
  osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1
  for _ in $(seq 1 20); do running || return 0; sleep 0.5; done
  return 1
}

since_line() { wc -l < "$LOG" | tr -d ' '; }
logged_since() { tail -n +"$(($1 + 1))" "$LOG" 2>/dev/null; }

# Wait for the log to show something, in what was written after `since`.
wait_for() {
  local pattern="$1" since="$2"
  for _ in $(seq 1 90); do
    logged_since "$since" | grep -q "$pattern" && return 0
    sleep 1
  done
  return 1
}

# A folder with a space in its name, because a path is where that goes wrong.
SCRATCH="$(mktemp -d)/opened with the app"
mkdir -p "$SCRATCH"
trap 'rm -rf "$(dirname "$SCRATCH")"' EXIT

write_csv() {
  printf 'title,description,priority,completed\n%s,Opened with the app,high,false\n' "$2" > "$1"
}

if /usr/libexec/PlistBuddy -c "Print :CFBundleDocumentTypes" "$APP/Contents/Info.plist" 2>/dev/null | grep -qi "csv"; then
  pass "the built app says it opens .csv files"
else
  fail "the built app does not say it opens .csv files"
fi
touch "$LOG"

# ── 1. The app is not running: the file starts it ────────────────────────────
quit || fail "could not quit the app before the test"
cold="Cold start $$"
write_csv "$SCRATCH/cold.csv" "$cold"
since="$(since_line)"
open -a "$APP" "$SCRATCH/cold.csv"

if wait_for 'Started POST "/tasks/import"' "$since"; then
  pass "a file opened with the app closed is imported"
else
  fail "nothing was imported after a cold start"
fi
running || fail "the file did not start the app"

# ── 2. The app is running: the file goes to the window that is open ──────────
sleep 3
running_title="Running $$"
write_csv "$SCRATCH/running.csv" "$running_title"
since="$(since_line)"
open -a "$APP" "$SCRATCH/running.csv"

if wait_for 'Started POST "/tasks/import"' "$since"; then
  pass "a file opened with the app running is imported"
else
  fail "nothing was imported with the app running"
fi
sleep 3

# ── 3. One file, one import ──────────────────────────────────────────────────
imports="$(logged_since "$since" | grep -c 'Started POST "/tasks/import"')"
if [ "$imports" -eq 1 ]; then
  pass "the file was imported once, though the system reports it twice"
else
  fail "the file was imported $imports times"
fi

# ── 4. The file's path is not a page ─────────────────────────────────────────
if grep -q "No route matches \[GET\] \"$(dirname "$SCRATCH")" "$LOG"; then
  fail "the app asked the server for the file's path as a page"
else
  pass "the file's path was never asked of the server as a page"
fi

# ── 5. The tasks are there ───────────────────────────────────────────────────
found="$(bin/rails runner "puts Task.where(title: ['$cold', '$running_title']).count" 2>/dev/null | tail -n 1)"
if [ "$found" = "2" ]; then
  pass "both files' tasks are in the list"
else
  fail "expected 2 imported tasks, found ${found:-none}"
fi
bin/rails runner "Task.where(title: ['$cold', '$running_title']).destroy_all" >/dev/null 2>&1

quit || fail "the app did not quit"

echo
[ "$failures" -eq 0 ] && echo "all passed" || echo "$failures failed"
exit "$failures"
