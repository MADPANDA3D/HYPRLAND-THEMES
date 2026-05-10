#!/usr/bin/env bash
set -euo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
    printf '󰂲\n'
    exit 0
fi

controller="$(bluetoothctl show 2>/dev/null || true)"
if [[ -z "$controller" ]]; then
    printf '󰂲\n'
    exit 0
fi

powered="$(awk -F': ' '/Powered:/ {print $2; exit}' <<<"$controller")"
if [[ "$powered" != "yes" ]]; then
    printf '󰂲\n'
    exit 0
fi

connected="$(bluetoothctl devices Connected 2>/dev/null || true)"
if grep -q '^Device ' <<<"$connected"; then
    printf '󰂱\n'
else
    printf '󰂯\n'
fi
