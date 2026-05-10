#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
    printf 'GPU n/a\n'
    exit 0
fi

IFS=',' read -r usage temp < <(
    nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null |
        head -n 1 |
        tr -d ' '
)

usage="${usage:-0}"
temp="${temp:-0}"
printf 'GPU %s%% %sC\n' "$usage" "$temp"
