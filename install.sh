#!/bin/bash
# Local source installer. No network downloads, sudo, SSH changes or security overrides.
set -euo pipefail
cd "$(dirname "$0")"
DEST="$HOME/Applications"
REPLACE=false
LAUNCH=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --destination) [[ $# -ge 2 && -n "$2" ]] || { echo '--destination requires a directory' >&2; exit 2; }; DEST="$2"; shift 2 ;;
        --replace) REPLACE=true; shift ;;
        --no-open) LAUNCH=false; shift ;;
        --help) echo 'Usage: ./install.sh [--destination DIRECTORY] [--replace] [--no-open]'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done
[[ ! -L "$DEST" ]] || { echo 'Refusing a symlink destination.' >&2; exit 1; }
mkdir -p "$DEST"
DEST=$(cd "$DEST" && pwd -P)
[[ "$DEST" != "$(pwd -P)" ]] || { echo 'Use a destination outside the source checkout.' >&2; exit 1; }
APP="$DEST/NodePeek.app"
[[ ! -L "$APP" ]] || { echo 'Refusing to replace a symlink application.' >&2; exit 1; }
if [[ -e "$APP" && "$REPLACE" != true ]]; then
    echo 'NodePeek already exists. Quit it, then use --replace to upgrade with an archive backup.' >&2
    exit 1
fi
./build.sh
STAGING=$(mktemp -d "$DEST/.nodepeek-install.XXXXXX")
cleanup() {
    if [[ -d "$STAGING/previous.app" && ! -e "$APP" ]]; then mv "$STAGING/previous.app" "$APP"; fi
    rm -rf "$STAGING"
}
trap cleanup EXIT
/usr/bin/ditto NodePeek.app "$STAGING/NodePeek.app"
/usr/bin/codesign --verify --deep --strict "$STAGING/NodePeek.app"
if [[ -e "$APP" ]]; then
    [[ -d "$APP" ]] || { echo 'Destination application is not a directory.' >&2; exit 1; }
    BACKUP=$(mktemp -d "$DEST/NodePeek-backup.XXXXXX")
    /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$BACKUP/NodePeek.zip"
    echo "Previous app backup: $BACKUP/NodePeek.zip"
    mv "$APP" "$STAGING/previous.app"
fi
mv "$STAGING/NodePeek.app" "$APP"
printf 'Installed: %s\n' "$APP"
printf 'Version: %s\n' "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
if [[ "$LAUNCH" == true ]]; then /usr/bin/open "$APP"; fi
