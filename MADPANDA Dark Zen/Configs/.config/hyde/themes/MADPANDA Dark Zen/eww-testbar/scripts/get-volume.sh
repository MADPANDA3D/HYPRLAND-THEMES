#!/usr/bin/env bash
set -euo pipefail

pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk '/Volume:/ {gsub(/%/, "", $5); print $5; exit}'
