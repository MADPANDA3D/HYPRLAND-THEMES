#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
theme_name="MADPANDA Dark Zen"
theme_json="${XDG_CONFIG_HOME:-$HOME/.config}/hyde/themes/$theme_name/theme.json"
default_about_url="https://github.com/MADPANDA3D/HYPRLAND-THEMES"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a MADPANDA "MADPANDA Eww test bar" "$1"
    else
        printf '%s\n' "$1" >&2
    fi
}

about_url() {
    local value=""
    if [[ -r "$theme_json" ]] && command -v jq >/dev/null 2>&1; then
        value="$(
            jq -r '.distribution.repositoryUrl // .distribution.repository // .about.url // empty' "$theme_json" 2>/dev/null
        )"
    fi
    printf '%s\n' "${value:-$default_about_url}"
}

case "$action" in
    audio)
        exec sh -c 'pavucontrol-qt -t 3 || pavucontrol -t 3 || pavucontrol'
        ;;
    mic)
        exec sh -c 'pavucontrol-qt -t 4 || pavucontrol -t 4 || pavucontrol'
        ;;
    network)
        if command -v nm-connection-editor >/dev/null 2>&1; then
            exec nm-connection-editor
        fi
        notify "Network editor is not installed. Use the existing Waybar tray or terminal NetworkManager tools for now."
        ;;
    bluetooth)
        if command -v blueman-manager >/dev/null 2>&1; then
            exec blueman-manager
        fi
        if command -v blueberry >/dev/null 2>&1; then
            exec blueberry
        fi
        notify "Bluetooth is controlled from the existing tray or bluetoothctl for now."
        ;;
    gamma)
        if command -v mad-display-gamma >/dev/null 2>&1; then
            exec mad-display-gamma popup
        fi
        notify "Gamma helper is unavailable."
        ;;
    eye-care)
        if command -v mad-display-gamma >/dev/null 2>&1; then
            exec mad-display-gamma popup
        fi
        notify "Eye care helper is unavailable."
        ;;
    animations)
        if command -v hyde-shell >/dev/null 2>&1; then
            exec hyde-shell animations --select
        fi
        notify "HyDE animations selector is unavailable."
        ;;
    workflows)
        if command -v hyde-shell >/dev/null 2>&1; then
            exec hyde-shell workflows --select
        fi
        notify "HyDE workflows selector is unavailable."
        ;;
    updates)
        if command -v hyde-shell >/dev/null 2>&1; then
            exec hyde-shell app system.update.sh up
        fi
        notify "HyDE update helper is unavailable."
        ;;
    weather)
        if command -v hyde-shell >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
            weather="$(timeout 8 hyde-shell weather 2>/dev/null || true)"
            title="$(jq -r '.text // "Weather"' <<<"$weather" 2>/dev/null)"
            body="$(jq -r '.tooltip // ""' <<<"$weather" 2>/dev/null | sed -E 's/<[^>]+>//g' | head -n 8)"
            notify "${title:-Weather}${body:+
$body}"
            exit 0
        fi
        notify "Weather helper is unavailable."
        ;;
    clipboard)
        if command -v hyde-shell >/dev/null 2>&1; then
            exec hyde-shell cliphist -c
        fi
        notify "Clipboard helper is unavailable."
        ;;
    keybinds)
        if command -v hyde-shell >/dev/null 2>&1; then
            exec hyde-shell keybinds_hint
        fi
        notify "Keybind helper is unavailable."
        ;;
    theme)
        if command -v hyde-shell >/dev/null 2>&1; then
            exec hyde-shell themeselect
        fi
        notify "Theme selector is unavailable."
        ;;
    wallpaper)
        if command -v hyde-shell >/dev/null 2>&1; then
            exec hyde-shell wallpaper --select --global
        fi
        notify "Wallpaper selector is unavailable."
        ;;
    about)
        if command -v xdg-open >/dev/null 2>&1; then
            exec xdg-open "$(about_url)"
        fi
        notify "About URL: $(about_url)"
        ;;
    *)
        notify "Unknown test-bar action: ${action:-none}"
        ;;
esac
