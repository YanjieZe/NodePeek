#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
swiftc -swift-version 5 -D SMOKE_TEST -parse-as-library -target arm64-apple-macosx13.0 Sources/*.swift Tests/Core.swift -o "$TEST_DIR/core-tests"
REMOTEMETER_LANGUAGE=en "$TEST_DIR/core-tests"
REMOTEMETER_LANGUAGE=zh-Hans "$TEST_DIR/core-tests"
python3 Tests/test_collector.py
