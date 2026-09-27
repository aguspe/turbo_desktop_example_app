#!/usr/bin/env bash
# bin/demo-reset must refuse while something is listening on the app's port.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT=3997
failures=0

fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
listener=$!
trap 'kill "$listener" 2>/dev/null' EXIT
for _ in 1 2 3 4 5 6 7 8 9 10; do
  lsof -nP -t -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1 && break
  sleep 0.3
done

before="$(cksum < "$ROOT/db/development.sqlite3" 2>/dev/null || echo none)"
output="$(PORT="$PORT" "$ROOT/bin/demo-reset" 2>&1)"
status=$?
after="$(cksum < "$ROOT/db/development.sqlite3" 2>/dev/null || echo none)"

[ "$status" -eq 1 ] || fail "expected exit 1 while the port is busy, got $status"
echo "$output" | grep -q "Quit the app first" || fail "expected a message saying to quit the app, got: $output"
[ "$before" = "$after" ] || fail "the database changed although the reset was refused"

[ "$failures" -eq 0 ] && echo "PASS: demo-reset refuses while the app is running"
exit "$failures"
