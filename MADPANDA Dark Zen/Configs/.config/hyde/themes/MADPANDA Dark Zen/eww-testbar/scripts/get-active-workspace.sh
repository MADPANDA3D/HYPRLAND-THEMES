#!/usr/bin/env bash
set -euo pipefail

current_workspace() {
    hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .activeWorkspace.id' 2>/dev/null | head -n 1
}

current_workspace || printf '1\n'

socket="${XDG_RUNTIME_DIR:-}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
[[ -S "$socket" ]] || exit 0

socat -u "UNIX-CONNECT:$socket" - 2>/dev/null | while IFS= read -r event; do
    case "$event" in
        workspace*|focusedmon*|activewindow*|createworkspace*|destroyworkspace*)
            current_workspace || printf '1\n'
            ;;
    esac
done
