#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
installer="$script_dir/install.sh"

launch_terminal() {
    local command
    printf -v command 'cd %q && exec %q "$@"' "$script_dir" "$installer"

    if command -v kitty >/dev/null 2>&1; then
        exec kitty --title "MADPANDA Dark Zen Installer" bash -lc "$command" bash "$@"
    elif command -v konsole >/dev/null 2>&1; then
        exec konsole --workdir "$script_dir" -e bash "$installer" "$@"
    elif command -v alacritty >/dev/null 2>&1; then
        exec alacritty --working-directory "$script_dir" -e bash "$installer" "$@"
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        exec xfce4-terminal --working-directory="$script_dir" --command="bash '$installer' $*"
    elif command -v gnome-terminal >/dev/null 2>&1; then
        exec gnome-terminal --working-directory="$script_dir" -- bash "$installer" "$@"
    elif command -v xterm >/dev/null 2>&1; then
        exec xterm -T "MADPANDA Dark Zen Installer" -e bash "$installer" "$@"
    fi

    printf 'No supported terminal emulator was found. Open a terminal here and run:\n  bash %q' "$installer" >&2
    printf ' %q' "$@" >&2
    printf '\n' >&2
    exit 1
}

if [[ ! -t 1 && -z "${MADPANDA_DARK_ZEN_TERMINAL_LAUNCHED:-}" ]]; then
    export MADPANDA_DARK_ZEN_TERMINAL_LAUNCHED=1
    launch_terminal "$@"
fi

exec bash "$installer" "$@"
