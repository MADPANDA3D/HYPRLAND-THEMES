#!/usr/bin/env bash
set -euo pipefail

weather_text=""
if command -v hyde-shell >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    weather_text="$(
        timeout 8 hyde-shell weather 2>/dev/null |
            jq -r '.text // empty' 2>/dev/null
    )" || weather_text=""
fi

summary="${weather_text%%|*}"
summary="${summary#"${summary%%[![:space:]]*}"}"
summary="${summary%"${summary##*[![:space:]]}"}"

if [[ -z "$summary" ]]; then
    printf 'Weather\n'
    exit 0
fi

icon="${summary%% *}"
rest="${summary#* }"
temp_token="${rest%% *}"
temp_ascii="$(printf '%s' "$temp_token" | tr -cd '0-9.-CF')"

if [[ "$temp_ascii" == *C && "$temp_ascii" =~ ^-?[0-9]+(\.[0-9]+)?C$ ]]; then
    celsius="${temp_ascii%C}"
    fahrenheit="$(awk -v c="$celsius" 'BEGIN { printf "%.0fF", (c * 9 / 5) + 32 }')"
    printf '%s %s\n' "$icon" "$fahrenheit"
else
    printf '%s\n' "$summary"
fi
