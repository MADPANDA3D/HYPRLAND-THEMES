#!/usr/bin/env bash
set -euo pipefail

if command -v mad-lock-session >/dev/null 2>&1; then
    exec mad-lock-session
fi

exec loginctl lock-session
