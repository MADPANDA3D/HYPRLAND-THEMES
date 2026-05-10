#!/usr/bin/env bash
set -euo pipefail

if command -v hyde-shell >/dev/null 2>&1; then
    timeout 8 hyde-shell weather 2>/dev/null |
        jq -r '.text // "Weather"' 2>/dev/null && exit 0
fi

printf 'Weather\n'
