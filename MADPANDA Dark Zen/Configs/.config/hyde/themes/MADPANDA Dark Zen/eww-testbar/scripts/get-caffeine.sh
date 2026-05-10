#!/usr/bin/env bash
set -euo pipefail

if command -v mad-caffeine >/dev/null 2>&1; then
    state="$(mad-caffeine status 2>/dev/null || printf 'inactive')"
else
    state="inactive"
fi

case "$state" in
    active)
        printf 'Caffeine Mode Active\n'
        ;;
    *)
        printf 'Caffeine Mode Inactive\n'
        ;;
esac
