#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT
DEST="$TEST_ROOT/Applications with spaces"
./install.sh --destination "$DEST" --no-open
APP="$DEST/NodePeek.app"
test -x "$APP/Contents/MacOS/NodePeek"
test -f "$APP/Contents/Resources/collector.py"
test -f "$APP/Contents/Resources/MenuIcon.png"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" = local.remotemeter.app
if ./install.sh --destination "$DEST" --no-open >"$TEST_ROOT/refusal" 2>&1; then
    echo 'FAIL: silently overwrote existing app' >&2; exit 1
fi
rg -q 'already exists' "$TEST_ROOT/refusal" 2>/dev/null || /usr/bin/grep -q 'already exists' "$TEST_ROOT/refusal"
./install.sh --destination "$DEST" --replace --no-open
codesign --verify --deep --strict "$APP"
BACKUPS=("$DEST"/NodePeek-backup.*/NodePeek.zip)
test "${#BACKUPS[@]}" -eq 1
ditto -x -k "${BACKUPS[0]}" "$TEST_ROOT/restored"
codesign --verify --deep --strict "$TEST_ROOT/restored/NodePeek.app"
echo 'PASS: clean install, path with spaces, overwrite refusal, upgrade, restorable backup and bundle resources'
