#!/usr/bin/env bash
set -euo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
    printf 'Bluetooth n/a\n'
    exit 0
fi

controller="$(bluetoothctl show 2>/dev/null || true)"
if [[ -z "$controller" ]]; then
    printf 'Bluetooth unavailable\n'
    exit 0
fi

powered="$(awk -F': ' '/Powered:/ {print $2; exit}' <<<"$controller")"
if [[ "$powered" != "yes" ]]; then
    printf 'Bluetooth off\n'
    exit 0
fi

connected="$(
    bluetoothctl devices Connected 2>/dev/null |
        sed -E 's/^Device [[:xdigit:]:]+ //' |
        paste -sd ', ' -
)"

if [[ -n "$connected" ]]; then
    printf 'BT %s\n' "$connected"
else
    printf 'Bluetooth on\n'
fi
