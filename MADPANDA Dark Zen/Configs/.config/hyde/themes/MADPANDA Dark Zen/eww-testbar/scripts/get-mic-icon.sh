#!/usr/bin/env bash
set -euo pipefail

muted="$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}')"
if [[ "$muted" == "yes" ]]; then
    printf '\n'
else
    printf '\n'
fi
