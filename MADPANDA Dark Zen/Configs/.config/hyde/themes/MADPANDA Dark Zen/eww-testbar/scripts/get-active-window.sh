#!/usr/bin/env bash
set -euo pipefail

active_window() {
    hyprctl activewindow -j 2>/dev/null |
        jq -r '
            if (.title // "") != "" then
                .title
            elif (.class // "") != "" then
                .class
            else
                "Desktop"
            end
        ' 2>/dev/null |
        head -n 1
}

active_window || printf 'Desktop\n'

socket="${XDG_RUNTIME_DIR:-}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
[[ -S "$socket" ]] || exit 0

socat -u "UNIX-CONNECT:$socket" - 2>/dev/null | while IFS= read -r event; do
    case "$event" in
        activewindow*|activewindowv2*|openwindow*|closewindow*|workspace*|focusedmon*)
            active_window || printf 'Desktop\n'
            ;;
    esac
done
