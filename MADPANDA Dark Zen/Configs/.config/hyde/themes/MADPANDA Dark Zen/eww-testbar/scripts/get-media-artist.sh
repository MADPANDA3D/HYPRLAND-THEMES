#!/usr/bin/env bash
set -euo pipefail

scripts="$HOME/.config/madpanda/eww-testbar/MADPANDA-Dark-Zen/scripts"
artist=""
source=""
pandora_artist=""

pandora_artist="$("$scripts/get-pandora-cache-field.sh" artist 2>/dev/null || true)"
if [[ -n "$pandora_artist" ]]; then
    printf '%s\n' "$pandora_artist"
    exit 0
fi

if command -v playerctl >/dev/null 2>&1; then
    artist="$(timeout 1.5s playerctl metadata xesam:artist 2>/dev/null || true)"
    source="$(timeout 1.5s playerctl metadata --format '{{playerName}}' 2>/dev/null || true)"
fi

case "$source" in
    chromium)
        if pgrep -x chrome >/dev/null 2>&1; then
            source="Google Chrome"
        fi
        ;;
esac

if [[ -n "$artist" ]]; then
    printf '%s\n' "$artist"
elif [[ -n "$source" ]]; then
    printf 'Source: %s\n' "$source"
else
    printf 'Open media to fill this card\n'
fi
