#!/usr/bin/env bash
set -euo pipefail

scripts="$HOME/.config/madpanda/eww-testbar/MADPANDA-Dark-Zen/scripts"
status=""
bridge_status=""

if command -v playerctl >/dev/null 2>&1; then
    status="$(timeout 1.5s playerctl status 2>/dev/null || true)"
fi

bridge_status="$("$scripts/get-pandora-cache-field.sh" status 2>/dev/null || true)"
[[ -n "$status" ]] || status="$bridge_status"

case "$status" in
    Playing)
        printf '\n'
        ;;
    *)
        printf '\n'
        ;;
esac
