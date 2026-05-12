#!/usr/bin/env bash
set -euo pipefail

scripts="$HOME/.config/madpanda/eww-testbar/MADPANDA-Dark-Zen/scripts"
status=""
pandora_title=""

if command -v playerctl >/dev/null 2>&1; then
    status="$(timeout 1.5s playerctl status 2>/dev/null || true)"
fi

pandora_title="$("$scripts/get-pandora-cache-field.sh" title 2>/dev/null || true)"
if [[ -z "$status" && -n "$pandora_title" ]]; then
    status="Pandora bridge"
fi

printf '%s\n' "${status:-Standby}"
