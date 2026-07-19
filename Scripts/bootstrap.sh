#!/bin/sh
# Generates OpenStopTimer.xcodeproj from project.yml via XcodeGen.
set -e
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen not found. Install it with: brew install xcodegen" >&2
    exit 1
fi

xcodegen generate
echo "Generated OpenStopTimer.xcodeproj — open it with: open OpenStopTimer.xcodeproj"
