#!/bin/bash
set -euo pipefail
fail() { printf 'NodePeek: %s\n' "$*" >&2; exit 1; }
[[ "$(uname -s)" == Darwin ]] || fail 'Requires macOS; Linux and Windows clients are not supported.'
[[ "$(uname -m)" == arm64 ]] || fail 'Requires an Apple Silicon Mac and a native arm64 terminal (not Rosetta).'
MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[[ "$MAJOR" -ge 13 ]] || fail 'Requires macOS 13 or later.'
xcrun --find swiftc >/dev/null 2>&1 || fail 'Install Apple Command Line Tools with xcode-select --install, finish the Apple installer, then retry.'
SDK=$(xcrun --sdk macosx --show-sdk-version 2>/dev/null) || fail 'A macOS SDK is required. Finish installing Apple Command Line Tools or Xcode.'
[[ "${SDK%%.*}" -ge 13 ]] || fail 'Requires a macOS 13+ SDK (Xcode 14+ or compatible Command Line Tools).'
printf 'Requirements OK: macOS %s, arm64, SDK %s\n' "$(sw_vers -productVersion)" "$SDK"
