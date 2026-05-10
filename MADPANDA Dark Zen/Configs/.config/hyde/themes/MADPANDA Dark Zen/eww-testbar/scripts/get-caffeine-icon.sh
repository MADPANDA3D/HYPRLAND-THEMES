#!/usr/bin/env bash
set -euo pipefail

if command -v mad-caffeine >/dev/null 2>&1; then
    mad-caffeine icon 2>/dev/null || printf '󱻊\n'
else
    printf '󱻊\n'
fi
