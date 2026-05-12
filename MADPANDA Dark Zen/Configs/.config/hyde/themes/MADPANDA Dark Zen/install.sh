#!/usr/bin/env bash
set -euo pipefail

script_path="${BASH_SOURCE[0]}"
theme_dir="$(cd "$(dirname "$script_path")" && pwd)"
theme_root="${XDG_CONFIG_HOME:-$HOME/.config}/hyde/themes"
local_bin="${XDG_BIN_HOME:-$HOME/.local/bin}"
theme_name="MADPANDA Dark Zen"
theme_slug="MADPANDA-Dark-Zen"
live_dir="$theme_root/$theme_name"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/madpanda/themes/$theme_slug"
features_file="$config_dir/features.env"
sdk_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/madpanda/rgb"
sdk_registry_file="$sdk_config_dir/sdk.env"
dry_run="0"
assume_yes="0"
no_prompt="0"
install_profile="desktop"
enable_csv=""
disable_csv=""

usage() {
    cat <<'EOF'
Usage:
  install.sh [--dry-run] [--yes] [--no-prompt] [--profile auto|desktop|laptop-light] [--enable a,b] [--disable a,b]

Installs the MADPANDA Dark Zen HyDE theme and prompts for optional modules:
sounds, rgb, identity, effects, sddm, grub, high-res wallpapers,
vertical wallpapers, animated wallpaper pilots, and bar provider.

Profiles:
  auto          Detect laptop/desktop and choose a matching profile.
  laptop-light Battery-safe travel setup: Eww, sounds, identity, effects on;
                RGB, high-res, and animated wallpapers off by default.
  desktop      Fuller visual setup for plugged-in workstations.
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) dry_run="1" ;;
        --yes) assume_yes="1" ;;
        --no-prompt) no_prompt="1" ;;
        --profile)
            shift
            install_profile="${1:-desktop}"
            ;;
        --laptop-light)
            install_profile="laptop-light"
            ;;
        --enable)
            shift
            enable_csv="${1:-}"
            ;;
        --disable)
            shift
            disable_csv="${1:-}"
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
    shift || true
done

case "$install_profile" in
    auto|desktop|laptop-light) ;;
    *)
        printf 'Unknown install profile: %s\n' "$install_profile" >&2
        usage >&2
        exit 2
        ;;
esac

repo_root=""
if [[ -d "$theme_dir/../../scripts" && -d "$theme_dir/../../themes" ]]; then
    repo_root="$(cd "$theme_dir/../.." && pwd)"
fi

in_csv() {
    local needle="$1"
    local csv="$2"
    local item
    IFS=',' read -ra items <<<"$csv"
    for item in "${items[@]}"; do
        item="${item#"${item%%[![:space:]]*}"}"
        item="${item%"${item##*[![:space:]]}"}"
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

detect_machine_profile() {
    local chassis=""
    if compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
        printf 'laptop-light\n'
        return 0
    fi
    if command -v hostnamectl >/dev/null 2>&1; then
        chassis="$(hostnamectl chassis 2>/dev/null || true)"
        case "$chassis" in
            laptop|convertible|tablet|handset) printf 'laptop-light\n'; return 0 ;;
            desktop|tower|server|vm|container) printf 'desktop\n'; return 0 ;;
        esac
    fi
    if [[ -r /sys/class/dmi/id/chassis_type ]]; then
        case "$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || true)" in
            8|9|10|11|14|30|31|32) printf 'laptop-light\n'; return 0 ;;
            3|4|5|6|7|13|23) printf 'desktop\n'; return 0 ;;
        esac
    fi
    return 1
}

resolve_install_profile() {
    local detected answer
    [[ "$install_profile" == "auto" ]] || return 0
    detected="$(detect_machine_profile || true)"
    if [[ -n "$detected" ]]; then
        install_profile="$detected"
        printf 'Auto profile detected: %s\n' "$install_profile" >&2
        return 0
    fi
    if [[ "$dry_run" == "1" || "$no_prompt" == "1" || "$assume_yes" == "1" ]]; then
        install_profile="laptop-light"
        printf 'Auto profile could not detect hardware; defaulting to laptop-light.\n' >&2
        return 0
    fi
    printf 'Could not detect laptop vs desktop. Use laptop-light profile? [Y/n] ' >&2
    read -r answer
    case "$answer" in
        n|N|no|NO) install_profile="desktop" ;;
        *) install_profile="laptop-light" ;;
    esac
}

openrgb_available() {
    command -v OpenRGB >/dev/null 2>&1 || command -v openrgb >/dev/null 2>&1
}

browser_available() {
    command -v google-chrome-stable >/dev/null 2>&1 ||
        command -v google-chrome >/dev/null 2>&1 ||
        command -v chromium >/dev/null 2>&1
}

ask_feature() {
    local feature="$1"
    local label="$2"
    local default="$3"
    local detail="${4:-}"
    local answer

    if in_csv "$feature" "$enable_csv"; then
        printf '1\n'
        return 0
    fi
    if in_csv "$feature" "$disable_csv"; then
        printf '0\n'
        return 0
    fi
    if [[ "$dry_run" == "1" ]]; then
        printf '%s\n' "$default"
        return 0
    fi
    if [[ "$assume_yes" == "1" ]]; then
        if [[ "$install_profile" == "laptop-light" ]]; then
            printf '%s\n' "$default"
        else
            printf '1\n'
        fi
        return 0
    fi
    if [[ "$no_prompt" == "1" ]]; then
        printf '%s\n' "$default"
        return 0
    fi

    if [[ -n "$detail" ]]; then
        printf '\n%s\n' "$detail" >&2
    fi
    if [[ "$default" == "1" ]]; then
        printf '%s [Y/n] ' "$label" >&2
    else
        printf '%s [y/N] ' "$label" >&2
    fi
    read -r answer
    case "$answer" in
        y|Y|yes|YES) printf '1\n' ;;
        n|N|no|NO) printf '0\n' ;;
        *) printf '%s\n' "$default" ;;
    esac
}

ask_bar_provider() {
    local answer
    if in_csv eww_bar "$enable_csv" || in_csv eww "$enable_csv"; then
        printf 'eww\n'
        return 0
    fi
    if in_csv waybar_bar "$enable_csv" || in_csv waybar "$enable_csv"; then
        printf 'waybar\n'
        return 0
    fi
    if [[ "$dry_run" == "1" || "$no_prompt" == "1" || "$assume_yes" == "1" ]]; then
        printf 'eww\n'
        return 0
    fi
    printf '\nDark Zen Eww bar replaces visible Waybar with the approved oval top bar. Waybar remains installed and recoverable.\n' >&2
    printf 'Use Dark Zen Eww bar instead of HyDE/Waybar? [Y/n] ' >&2
    read -r answer
    case "$answer" in
        n|N|no|NO) printf 'waybar\n' ;;
        *) printf 'eww\n' ;;
    esac
}

run() {
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

sddm_available() {
    command -v sddm >/dev/null 2>&1 && return 0
    command -v sddm-greeter >/dev/null 2>&1 && return 0
    systemctl list-unit-files sddm.service >/dev/null 2>&1 && return 0
    pacman -Q sddm >/dev/null 2>&1 && return 0
    return 1
}

has_vertical_outputs() {
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v jq >/dev/null 2>&1 || return 1
    hyprctl monitors -j 2>/dev/null | jq -e '
        any(.[]; ((.transform // 0) as $transform | ([1,3,5,7] | index($transform)) != null) or ((.height // 0) > (.width // 0)))
    ' >/dev/null 2>&1
}

install_sddm_display_manager() {
    sddm_available && return 0
    if command -v pacman >/dev/null 2>&1; then
        run sudo pacman -S --needed sddm
        run sudo systemctl enable sddm.service
    elif command -v yay >/dev/null 2>&1; then
        run yay -S --needed sddm
        run sudo systemctl enable sddm.service
    else
        printf 'SDDM install requested, but neither pacman nor yay is available.\n' >&2
        return 1
    fi
}

copy_core_theme() {
    if [[ "$theme_dir" == "$live_dir" ]]; then
        return 0
    fi
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] mkdir -p %q\n' "$live_dir"
    else
        mkdir -p "$live_dir"
    fi
    run rsync -a --delete \
        --exclude 'wall.*' \
        --exclude 'wallpapers.previous-*' \
        --exclude 'wallpapers.rejected-*' \
        "$theme_dir/" "$live_dir/"
}

helper_source_for() {
    local helper="$1"
    if [[ -n "$repo_root" && -r "$repo_root/scripts/$helper" ]]; then
        printf '%s/scripts/%s\n' "$repo_root" "$helper"
    elif [[ -r "$theme_dir/helpers/bin/$helper" ]]; then
        printf '%s/helpers/bin/%s\n' "$theme_dir" "$helper"
    elif [[ -r "$live_dir/helpers/bin/$helper" ]]; then
        printf '%s/helpers/bin/%s\n' "$live_dir" "$helper"
    fi
}

install_helpers() {
    local helper source
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] mkdir -p %q\n' "$local_bin"
    else
        mkdir -p "$local_bin"
    fi
    for helper in \
        mad-theme-pack \
        mad-theme-safe \
        mad-theme-sound \
        mad-session-start \
        mad-lock-session \
        mad-lock-tiles \
        mad-lock-surfaces \
        mad-lock-widgets \
        mad-lock-wallpaper \
        mad-lock-preview-widgets \
        mad-rgb-theme \
        mad-openrgb-sdkctl \
        mad-rgb-system-clear \
        mad-theme-runtime \
        mad-theme-watcher \
        mad-lock-greet \
        mad-lock-quote \
        mad-dock-all-monitors \
        mad-waybar-safe \
        mad-window-close \
        mad-window-burst \
        mad-display-gamma \
        mad-screenshot-region \
        mad-screenshot-active-window \
        mad-screenshot-full \
        mad-keybinds-hint \
        mad-settings-menu \
        mad-wallpaper-theme \
        mad-theme-mode \
        mad-bar-provider \
        mad-caffeine \
        mad-media-control \
        mad-pandora-native-host \
        mad-pandora-dom-probe \
        mad-chrome-dark-zen \
        mad-eww-widgets \
        mad-eww-bar \
        mad-eww-testbar; do
        source="$(helper_source_for "$helper" || true)"
        [[ -n "$source" ]] || continue
        run install -m 0755 "$source" "$local_bin/$helper"
    done
}

write_features() {
    local sounds="$1"
    local rgb="$2"
    local identity="$3"
    local effects="$4"
    local sddm="$5"
    local grub="$6"
    local hires_wallpapers="$7"
    local vertical_wallpapers="$8"
    local animated_wallpapers="$9"
    local bar_provider="${10:-eww}"
    local profile="${11:-desktop}"

    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] write %s\n' "$features_file"
        return 0
    fi
    mkdir -p "$config_dir"
    {
        printf 'MAD_THEME_NAME=%q\n' "$theme_name"
        printf 'MAD_THEME_INSTALL_PROFILE=%q\n' "$profile"
        printf 'MAD_THEME_FEATURE_CORE=1\n'
        printf 'MAD_THEME_FEATURE_SOUNDS=%s\n' "$sounds"
        printf 'MAD_THEME_FEATURE_RGB=%s\n' "$rgb"
        printf 'MAD_THEME_FEATURE_IDENTITY=%s\n' "$identity"
        printf 'MAD_THEME_FEATURE_EFFECTS=%s\n' "$effects"
        printf 'MAD_THEME_FEATURE_SDDM=%s\n' "$sddm"
        printf 'MAD_THEME_FEATURE_GRUB=%s\n' "$grub"
        printf 'MAD_THEME_FEATURE_HIRES_WALLPAPERS=%s\n' "$hires_wallpapers"
        printf 'MAD_THEME_FEATURE_VERTICAL_WALLPAPERS=%s\n' "$vertical_wallpapers"
        printf 'MAD_THEME_FEATURE_ANIMATED_WALLPAPERS=%s\n' "$animated_wallpapers"
        printf 'MAD_THEME_BAR_PROVIDER=%q\n' "$bar_provider"
    } >"$features_file"
}

install_user_watcher() {
    local unit_source=""
    if [[ -n "$repo_root" && -r "$repo_root/systemd/user/mad-theme-watcher.service" ]]; then
        unit_source="$repo_root/systemd/user/mad-theme-watcher.service"
    elif [[ -r "$theme_dir/helpers/systemd/user/mad-theme-watcher.service" ]]; then
        unit_source="$theme_dir/helpers/systemd/user/mad-theme-watcher.service"
    elif [[ -r "$live_dir/helpers/systemd/user/mad-theme-watcher.service" ]]; then
        unit_source="$live_dir/helpers/systemd/user/mad-theme-watcher.service"
    fi
    [[ -n "$unit_source" ]] || return 0
    run install -D -m 0644 "$unit_source" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/mad-theme-watcher.service"
    if [[ "$dry_run" != "1" ]] && command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload >/dev/null 2>&1 || true
        systemctl --user enable --now mad-theme-watcher.service >/dev/null 2>&1 || true
    fi
}

sdk_socket_ready() {
    local helper host="${1:-127.0.0.1}" port="${2:-6742}"
    helper="$(helper_source_for mad-openrgb-sdkctl || command -v mad-openrgb-sdkctl 2>/dev/null || true)"
    [[ -n "$helper" && -x "$helper" ]] || return 1
    "$helper" --host "$host" --port "$port" plugin-list >/dev/null 2>&1
}

write_sdk_registry() {
    local provider="$1"
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] write %s\n' "$sdk_registry_file"
        return 0
    fi
    mkdir -p "$sdk_config_dir"
    {
        printf '# Generated by MADPANDA Dark Zen install.sh on %s\n' "$(date --iso-8601=seconds)"
        printf 'MAD_OPENRGB_SDK_ENABLED=1\n'
        printf 'MAD_OPENRGB_SDK_PROVIDER=%s\n' "$provider"
        printf 'MAD_OPENRGB_SDK_SERVICE=mad-openrgb-sdk.service\n'
        printf 'MAD_OPENRGB_SDK_HOST=127.0.0.1\n'
        printf 'MAD_OPENRGB_SDK_PORT=6742\n'
    } >"$sdk_registry_file"
}

install_openrgb_sdk_service() {
    local unit_source=""
    local provider="madpanda"
    if [[ -n "$repo_root" && -r "$repo_root/systemd/user/mad-openrgb-sdk.service" ]]; then
        unit_source="$repo_root/systemd/user/mad-openrgb-sdk.service"
    elif [[ -r "$theme_dir/helpers/systemd/user/mad-openrgb-sdk.service" ]]; then
        unit_source="$theme_dir/helpers/systemd/user/mad-openrgb-sdk.service"
    elif [[ -r "$live_dir/helpers/systemd/user/mad-openrgb-sdk.service" ]]; then
        unit_source="$live_dir/helpers/systemd/user/mad-openrgb-sdk.service"
    fi
    [[ -n "$unit_source" ]] || return 0
    if sdk_socket_ready 127.0.0.1 6742; then
        if ! systemctl --user is-active --quiet mad-openrgb-sdk.service 2>/dev/null; then
            provider="existing-socket"
        fi
    fi
    run install -D -m 0644 "$unit_source" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/mad-openrgb-sdk.service"
    write_sdk_registry "$provider"
    if [[ "$dry_run" != "1" ]] && command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload >/dev/null 2>&1 || true
        systemctl --user enable mad-openrgb-sdk.service >/dev/null 2>&1 || true
    fi
}

install_rgb_shutdown() {
    local unit_source=""
    local helper_source
    helper_source="$(helper_source_for mad-rgb-system-clear || true)"
    if [[ -n "$repo_root" && -r "$repo_root/systemd/system/mad-rgb-system-clear@.service" ]]; then
        unit_source="$repo_root/systemd/system/mad-rgb-system-clear@.service"
    elif [[ -r "$theme_dir/helpers/systemd/system/mad-rgb-system-clear@.service" ]]; then
        unit_source="$theme_dir/helpers/systemd/system/mad-rgb-system-clear@.service"
    elif [[ -r "$live_dir/helpers/systemd/system/mad-rgb-system-clear@.service" ]]; then
        unit_source="$live_dir/helpers/systemd/system/mad-rgb-system-clear@.service"
    fi
    [[ -n "$unit_source" && -n "$helper_source" ]] || return 0
    if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
        run sudo install -D -m 0755 "$helper_source" /usr/local/bin/mad-rgb-system-clear
        run sudo install -D -m 0644 "$unit_source" /etc/systemd/system/mad-rgb-system-clear@.service
        if [[ "$dry_run" != "1" ]]; then
            sudo systemctl disable --now mad-rgb-system-clear.service >/dev/null 2>&1 || true
            sudo rm -f /etc/systemd/system/mad-rgb-system-clear.service
            sudo systemctl daemon-reload
            sudo systemctl enable --now "mad-rgb-system-clear@${USER}.service"
        fi
    else
        printf 'RGB reboot reset needs sudo for the system shutdown service; skipped.\n' >&2
    fi
}

main() {
    local vertical_default="0"
    local vertical_label="Use portrait wallpapers on vertical monitors?"
    local sounds_default="0"
    local rgb_default="0"
    local identity_default="0"
    local effects_default="0"
    local grub_default="0"
    local hires_default="0"
    local animated_default="0"

    resolve_install_profile

    if [[ "$install_profile" == "laptop-light" ]]; then
        sounds_default="1"
        rgb_default="0"
        identity_default="1"
        effects_default="1"
        grub_default="0"
        hires_default="0"
        animated_default="0"
        vertical_default="0"
    else
        sounds_default="1"
        rgb_default="0"
        openrgb_available && rgb_default="1"
        identity_default="1"
        effects_default="1"
        grub_default="0"
        hires_default="1"
        animated_default="1"
        vertical_default="0"
    fi

    command -v rsync >/dev/null 2>&1 || {
        printf 'rsync is required for the core theme install.\n' >&2
        exit 1
    }

    sounds="$(ask_feature sounds 'Enable Dark Zen event sounds?' "$sounds_default" 'Installs theme-owned lock, unlock, boot, and tile-close sounds.')"
    rgb="$(ask_feature rgb 'Enable OpenRGB theme control?' "$rgb_default" 'Desktop RGB automation. Laptop-light keeps this off by default for battery and hardware portability.')"
    identity="$(ask_feature identity 'Enable Dark Zen lock/avatar/notification identity?' "$identity_default" 'Applies Dark Zen avatar, lock identity, notification styling, and related HyDE wallbash ownership.')"
    effects="$(ask_feature effects 'Enable tile-close sound hook?' "$effects_default" 'Enables the synthetic tile close effect and sound hook without screenshot capture.')"
    if sddm_available; then
        sddm="$(ask_feature sddm 'Use the Dark Zen SDDM login theme? Requires sudo.' 1 'Installs the Dark Zen SDDM wrapper while preserving the Corners-style login layout.')"
    else
        sddm="$(ask_feature sddm 'SDDM is not installed. Install and use SDDM as the login manager?' 0 'Optional display manager setup for systems that do not already use SDDM.')"
        if [[ "$sddm" == "1" ]]; then
            install_sddm_display_manager || sddm="0"
        fi
    fi
    grub="$(ask_feature grub 'Install GRUB artwork? Requires sudo and never regenerates GRUB automatically.' "$grub_default" 'Copies artwork only. This installer does not regenerate GRUB.')"
    hires_wallpapers="$(ask_feature hires_wallpapers 'Install/use the 4K high-res wallpaper pack?' "$hires_default" 'Large static wallpaper tier. Laptop-light keeps standard static wallpapers by default.')"
    if [[ "$install_profile" != "laptop-light" && "$no_prompt" != "1" ]] && has_vertical_outputs; then
        vertical_default="1"
        vertical_label="Use portrait wallpapers on detected vertical monitors?"
    fi
    vertical_wallpapers="$(ask_feature vertical_wallpapers "$vertical_label" "$vertical_default" 'Uses portrait assets on rotated or portrait monitors when available.')"
    animated_wallpapers="$(ask_feature animated_wallpapers 'Use animated GIF wallpaper pilots where available?' "$animated_default" 'Large animated wallpaper tier. Laptop-light keeps this off for battery and thermals.')"
    bar_provider="$(ask_bar_provider)"

    copy_core_theme
    install_helpers
    if [[ "$dry_run" != "1" && -x "$local_bin/mad-pandora-native-host" ]]; then
        "$local_bin/mad-pandora-native-host" --install-manifest >/dev/null 2>&1 || true
    fi
    if [[ "$dry_run" == "1" ]]; then
        if browser_available; then
            printf '[dry-run] install Chrome/Chromium Pandora media bridge\n'
        else
            printf '[dry-run] skip Pandora media bridge; Chrome/Chromium not found\n'
        fi
    elif [[ -x "$local_bin/mad-chrome-dark-zen" ]]; then
        if browser_available; then
            "$local_bin/mad-chrome-dark-zen" --install-desktop >/dev/null 2>&1 || true
            "$local_bin/mad-chrome-dark-zen" --install-extension || true
        else
            printf 'Chrome/Chromium not found; Pandora media bridge skipped. Install Google Chrome or Chromium and rerun this installer to enable it.\n' >&2
        fi
    fi
    write_features "$sounds" "$rgb" "$identity" "$effects" "$sddm" "$grub" "$hires_wallpapers" "$vertical_wallpapers" "$animated_wallpapers" "$bar_provider" "$install_profile"
    if [[ "$dry_run" != "1" && -x "$local_bin/mad-bar-provider" ]]; then
        "$local_bin/mad-bar-provider" set "$bar_provider" >/dev/null 2>&1 || true
    fi
    install_user_watcher
    if [[ "$rgb" == "1" ]]; then
        install_openrgb_sdk_service
        install_rgb_shutdown
    fi
    theme_pack_bin="$(helper_source_for mad-theme-pack || command -v mad-theme-pack 2>/dev/null || true)"
    if [[ -n "${theme_pack_bin:-}" ]]; then
        if [[ "$dry_run" == "1" ]]; then
            "$theme_pack_bin" apply "$theme_name" --dry-run || true
        else
            "$theme_pack_bin" apply "$theme_name" || true
        fi
    fi
    theme_runtime_bin="$(helper_source_for mad-theme-runtime || command -v mad-theme-runtime 2>/dev/null || true)"
    if [[ "$dry_run" != "1" && -n "${theme_runtime_bin:-}" ]]; then
        "$theme_runtime_bin" reconcile --startup >/dev/null 2>&1 || true
    fi

    printf 'MADPANDA Dark Zen install finished. Theme: %s\n' "$live_dir"
}

main "$@"
