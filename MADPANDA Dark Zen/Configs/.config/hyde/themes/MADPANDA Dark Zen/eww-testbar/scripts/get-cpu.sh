#!/usr/bin/env bash
set -euo pipefail

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_a=$((idle + iowait))
total_a=$((user + nice + system + idle + iowait + irq + softirq + steal))
sleep 0.2
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_b=$((idle + iowait))
total_b=$((user + nice + system + idle + iowait + irq + softirq + steal))

total_delta=$((total_b - total_a))
idle_delta=$((idle_b - idle_a))
if ((total_delta <= 0)); then
    printf '0\n'
else
    printf '%s\n' $(((100 * (total_delta - idle_delta)) / total_delta))
fi
