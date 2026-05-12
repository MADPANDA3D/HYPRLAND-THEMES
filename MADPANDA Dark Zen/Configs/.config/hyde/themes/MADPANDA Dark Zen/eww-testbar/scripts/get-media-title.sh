#!/usr/bin/env bash
set -euo pipefail

scripts="$HOME/.config/madpanda/eww-testbar/MADPANDA-Dark-Zen/scripts"
title=""
bridge_title=""
original_title=""

bridge_title="$("$scripts/get-pandora-cache-field.sh" title 2>/dev/null || true)"
if [[ -n "$bridge_title" ]]; then
    printf '%s\n' "$bridge_title"
    exit 0
fi

if command -v playerctl >/dev/null 2>&1; then
    title="$(timeout 1.5s playerctl metadata xesam:title 2>/dev/null || true)"
fi
original_title="$title"

case "$title" in
    *"Now Playing on Pandora"*|"Pandora"*|"")
        [[ -z "$original_title" ]] || title="$original_title"
        ;;
esac

printf '%s\n' "${title:-Nothing playing}"
