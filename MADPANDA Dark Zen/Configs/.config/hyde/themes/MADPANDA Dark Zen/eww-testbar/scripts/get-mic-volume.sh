#!/usr/bin/env bash
set -euo pipefail

pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null |
    awk '/Volume:/ {gsub(/%/, "", $5); print $5; found=1; exit} END {if (!found) print 0}'
