#!/usr/bin/env bash
set -euo pipefail

if command -v mad-display-gamma >/dev/null 2>&1; then
    mad-display-gamma json 2>/dev/null | jq -r '.text // "Gamma"' 2>/dev/null && exit 0
fi

printf 'Gamma\n'
