#!/usr/bin/env bash
set -euo pipefail

workspaces() {
    hyprctl workspaces -j 2>/dev/null |
        jq -c '
            [ .[] | select(.id > 0 and .id <= 9) | .id | tostring ] as $open |
            [ range(1; 10) | tostring as $id | {
                id: $id,
                occupied: ($open | index($id) != null)
            } ]
        ' 2>/dev/null
}

workspaces || printf '[]\n'

socket="${XDG_RUNTIME_DIR:-}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
[[ -S "$socket" ]] || exit 0

socat -u "UNIX-CONNECT:$socket" - 2>/dev/null | while IFS= read -r event; do
    case "$event" in
        workspace*|focusedmon*|createworkspace*|destroyworkspace*|moveworkspace*|openwindow*|closewindow*)
            workspaces || printf '[]\n'
            ;;
    esac
done
