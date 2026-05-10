#!/usr/bin/env bash
set -euo pipefail

if ! command -v sensors >/dev/null 2>&1; then
    printf 'n/a\n'
    exit 0
fi

temp="$(
    sensors 2>/dev/null |
        awk '
            /^k10temp-/ { in_cpu = 1; next }
            in_cpu && /^Tctl:/ {
                value = $2
                gsub(/[^0-9.-]/, "", value)
                printf "%.0fC\n", value
                found = 1
                exit
            }
            /^$/ { in_cpu = 0 }
            END {
                if (!found) exit 1
            }
        ' 2>/dev/null
)" || temp=""

if [[ -z "$temp" ]]; then
    temp="$(
        sensors 2>/dev/null |
            awk '
                /Package id 0:|Tctl:|temp1:/ {
                    value = $2
                    gsub(/[^0-9.-]/, "", value)
                    printf "%.0fC\n", value
                    found = 1
                    exit
                }
                END {
                    if (!found) exit 1
                }
            ' 2>/dev/null
    )" || temp=""
fi

printf '%s\n' "${temp:-n/a}"
