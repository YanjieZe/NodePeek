#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/Demo.app/Contents/MacOS .build/Demo.app/Contents/Resources docs/assets
cp Resources/AppIcon.icns Resources/MenuIcon.png .build/Demo.app/Contents/Resources/
swiftc -swift-version 5 -D SMOKE_TEST -parse-as-library -target arm64-apple-macosx13.0 Sources/*.swift Tests/Demo.swift -o .build/Demo.app/Contents/MacOS/Demo
for language in en zh-Hans; do
    REMOTEMETER_LANGUAGE="$language" .build/Demo.app/Contents/MacOS/Demo "$PWD/docs/assets"
done

if command -v ffmpeg >/dev/null 2>&1; then
    printf "file '%s/docs/assets/overview-en.png'\nduration 2.5\nfile '%s/docs/assets/detail-en.png'\nduration 2.5\nfile '%s/docs/assets/overview-en.png'\nduration 2.5\n" "$PWD" "$PWD" "$PWD" > .build/demo-frames.txt
    ffmpeg -y -v error -f concat -safe 0 -i .build/demo-frames.txt -vf 'fps=2,scale=900:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse' -loop 0 docs/assets/demo.gif
fi
