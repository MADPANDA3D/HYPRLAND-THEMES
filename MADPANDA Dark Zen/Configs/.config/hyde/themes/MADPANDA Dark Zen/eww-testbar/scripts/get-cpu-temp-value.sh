#!/usr/bin/env bash
set -euo pipefail

value="$("$HOME/.config/madpanda/eww-testbar/MADPANDA-Dark-Zen/scripts/get-temperature.sh" 2>/dev/null | tr -cd '0-9' || true)"
printf '%s\n' "${value:-0}"
