#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/madpanda/eww-widgets"
state_file="$state_dir/calendar.env"
runtime_dir="${XDG_CONFIG_HOME:-$HOME/.config}/madpanda/eww-testbar/MADPANDA-Dark-Zen"
calendar_script="$runtime_dir/scripts/get-calendar.sh"

current_offset() {
    local value="0"
    if [[ -r "$state_file" ]]; then
        value="$(sed -n 's/^MAD_EWW_CALENDAR_OFFSET=//p' "$state_file" | tail -n 1)"
    fi
    [[ "$value" =~ ^-?[0-9]+$ ]] || value="0"
    printf '%s\n' "$value"
}

write_offset() {
    local value="$1"
    mkdir -p "$state_dir"
    printf 'MAD_EWW_CALENDAR_OFFSET=%s\n' "$value" >"$state_file"
}

update_eww() {
    [[ -x "$calendar_script" ]] || return 0
    command -v eww >/dev/null 2>&1 || return 0
    eww --force-wayland -c "$runtime_dir" update drawer_calendar="$("$calendar_script")" >/dev/null 2>&1 || true
}

case "${1:-}" in
    previous|prev)
        write_offset "$(( $(current_offset) - 1 ))"
        ;;
    next)
        write_offset "$(( $(current_offset) + 1 ))"
        ;;
    today|current|reset)
        write_offset 0
        ;;
    -h|--help|help)
        printf 'Usage: calendar-action.sh previous|today|next\n'
        exit 0
        ;;
    *)
        printf 'Usage: calendar-action.sh previous|today|next\n' >&2
        exit 2
        ;;
esac

update_eww
