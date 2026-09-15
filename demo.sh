#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/Demo.app/Contents/MacOS .build/Demo.app/Contents/Resources docs/assets
cp Resources/AppIcon.icns Resources/MenuIcon.png .build/Demo.app/Contents/Resources/
swiftc -swift-version 5 -D SMOKE_TEST -parse-as-library -target arm64-apple-macosx13.0 Sources/*.swift Tests/Demo.swift -o .build/Demo.app/Contents/MacOS/Demo
for language in en zh-Hans; do
    NODEPEEK_LANGUAGE="$language" .build/Demo.app/Contents/MacOS/Demo "$PWD/docs/assets"
done

# Regenerate the animated README preview and MP4 with ./video.sh.
