#!/usr/bin/env bash
set -euo pipefail

free -m | awk '/^Mem:/ { printf "%.0f\n", ($3 / $2) * 100 }'
