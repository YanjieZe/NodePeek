#!/bin/bash
# Render actual SwiftUI views with synthetic data, then encode a 20-second silent tour.
set -euo pipefail
cd "$(dirname "$0")"
command -v ffmpeg >/dev/null || { echo 'Video generation requires ffmpeg.' >&2; exit 1; }
mkdir -p .build/Video.app/Contents/MacOS .build/Video.app/Contents/Resources docs/assets
FRAMES=$(mktemp -d "$PWD/.build/video-frames.XXXXXX")
trap 'rm -rf "$FRAMES"' EXIT
cp Resources/AppIcon.icns Resources/MenuIcon.png .build/Video.app/Contents/Resources/
xcrun --sdk macosx swiftc -swift-version 5 -D SMOKE_TEST -parse-as-library -target arm64-apple-macosx13.0 Sources/*.swift Tests/Demo.swift -o .build/Video.app/Contents/MacOS/Video
NODEPEEK_LANGUAGE=en .build/Video.app/Contents/MacOS/Video "$FRAMES" --video
ffmpeg -y -v error -framerate 4 -i "$FRAMES/frame-%04d.png" -vf 'scale=1100:720:flags=lanczos,fps=24' -c:v libx264 -crf 20 -preset medium -pix_fmt yuv420p -movflags +faststart -an docs/assets/demo.mp4
ffmpeg -y -v error -i docs/assets/demo.mp4 -vf 'fps=4,scale=880:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse' -loop 0 docs/assets/demo.gif
printf 'Created docs/assets/demo.mp4 and animated README preview\n'
