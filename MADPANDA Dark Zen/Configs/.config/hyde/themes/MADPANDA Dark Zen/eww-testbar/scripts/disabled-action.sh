#!/usr/bin/env bash
set -euo pipefail

action="${1:-system action}"
if command -v notify-send >/dev/null 2>&1; then
    notify-send "MADPANDA Eww test bar" "${action} is disabled in sandbox mode."
else
    printf 'MADPANDA Eww test bar: %s is disabled in sandbox mode.\n' "$action" >&2
fi
