#!/usr/bin/env bash
set -euo pipefail

if command -v hyde-shell >/dev/null 2>&1; then
    timeout 12 hyde-shell system.update 2>/dev/null |
        jq -r '.text // "Updates"' 2>/dev/null && exit 0
fi

printf 'Updates\n'
