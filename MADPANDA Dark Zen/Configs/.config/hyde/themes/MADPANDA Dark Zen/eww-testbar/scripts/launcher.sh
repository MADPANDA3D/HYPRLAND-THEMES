#!/usr/bin/env bash
set -euo pipefail

pkill -x rofi >/dev/null 2>&1 || true
if command -v hyde-shell >/dev/null 2>&1; then
    exec hyde-shell rofilaunch d
elif command -v hyprlauncher >/dev/null 2>&1; then
    exec hyprlauncher
elif command -v rofi >/dev/null 2>&1; then
    exec rofi -show drun
fi

notify-send "MADPANDA Eww test bar" "No launcher command found."
