#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
VERSION=$(tr -d '\n' < VERSION)
mkdir -p dist
ARCHIVE="RemoteMeter-${VERSION}-macOS-arm64.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent RemoteMeter.app "dist/$ARCHIVE"
(cd dist && /usr/bin/shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256")
printf 'Packaged dist/%s\n' "$ARCHIVE"
