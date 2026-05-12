#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
    printf '0\n'
    exit 0
fi

value="$(
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null |
        awk 'NR == 1 {gsub(/[^0-9]/, "", $0); print ($0 == "" ? 0 : $0)}'
)"
printf '%s\n' "${value:-0}"
