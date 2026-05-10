#!/usr/bin/env bash
set -euo pipefail

muted="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')"
volume="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk '/Volume:/ {gsub(/%/, "", $5); print $5; exit}')"
volume="${volume:-0}"

if [[ "$muted" == "yes" || "$volume" -le 0 ]]; then
    printf '󰝟\n'
elif [[ "$volume" -ge 60 ]]; then
    printf '\n'
else
    printf '\n'
fi
