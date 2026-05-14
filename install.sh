#!/usr/bin/env bash
set -euo pipefail

repo_url="${MADPANDA_HYPRLAND_THEMES_REPO:-https://github.com/MADPANDA3D/HYPRLAND-THEMES.git}"
script_source="${BASH_SOURCE[0]:-${0:-}}"
script_dir="$(cd "$(dirname "$script_source")" >/dev/null 2>&1 && pwd || true)"
if [[ -n "${MADPANDA_HYPRLAND_THEMES_DIR:-}" ]]; then
    repo_dir="$MADPANDA_HYPRLAND_THEMES_DIR"
elif [[ -n "$script_dir" && -d "$script_dir/MADPANDA Dark Zen" ]]; then
    repo_dir="$script_dir"
else
    repo_dir="$HOME/.local/share/madpanda/hyprland-themes"
fi

theme_name="MADPANDA Dark Zen"
theme_rel="MADPANDA Dark Zen"
theme_config_rel="Configs/.config/hyde/themes/MADPANDA Dark Zen"
hyde_dir="${MADPANDA_HYDE_DIR:-$HOME/HyDE}"
state_base="${XDG_STATE_HOME:-$HOME/.local/state}/madpanda/dark-zen-install"
run_id="${MADPANDA_INSTALL_RUN_ID:-$(date +%Y%m%dT%H%M%S%z)-$$}"
run_root="$state_base/runs/$run_id"
stage_dir="$state_base/stages"
log_dir="$run_root/logs"
resume_attempt_file="$state_base/resume-attempts"
hyprland_conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
resume_start="# MADPANDA-DARK-ZEN-RESUME-START"
resume_end="# MADPANDA-DARK-ZEN-RESUME-END"

dry_run="0"
assume_yes="0"
no_prompt="0"
profile="auto"
skip_hyde="0"
resume="0"
enable_csv=""
disable_csv=""

usage() {
    cat <<'EOF'
Usage:
  install.sh [--dry-run] [--yes] [--no-prompt] [--resume] [--profile auto|desktop|laptop-light] [--skip-hyde] [--enable a,b] [--disable a,b]

One-command bootstrap for MADPANDA Dark Zen on Arch/EndeavourOS.
The installer is staged: it installs HyDE first, writes a one-shot Hyprland
resume hook, asks for reboot, then applies Dark Zen after the next login.
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) dry_run="1" ;;
        --yes|-y) assume_yes="1" ;;
        --no-prompt) no_prompt="1" ;;
        --resume) resume="1" ;;
        --profile)
            shift
            profile="${1:-auto}"
            ;;
        --skip-hyde) skip_hyde="1" ;;
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

case "$profile" in
    auto|desktop|laptop-light) ;;
    *)
        printf 'Unknown profile: %s\n' "$profile" >&2
        usage >&2
        exit 2
        ;;
esac

mkdir -p "$log_dir" "$stage_dir"

log() {
    printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$log_dir/bootstrap.log" >&2
}

run() {
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        log "run: $*"
        "$@"
    fi
}

run_logged() {
    local log_file="$1"
    shift
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf ' | tee %q\n' "$log_file"
    else
        log "run_logged: $*"
        "$@" 2>&1 | tee "$log_file"
    fi
}

ask_yes_no() {
    local label="$1"
    local default="${2:-0}"
    local answer
    if [[ "$dry_run" == "1" || "$no_prompt" == "1" ]]; then
        printf '%s\n' "$default"
        return 0
    fi
    if [[ "$assume_yes" == "1" ]]; then
        printf '1\n'
        return 0
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

mark_stage() {
    local stage="$1"
    [[ "$dry_run" == "1" ]] && { printf '[dry-run] mark stage %s\n' "$stage"; return 0; }
    mkdir -p "$stage_dir"
    date --iso-8601=seconds >"$stage_dir/$stage.done"
}

stage_done() {
    [[ -r "$stage_dir/$1.done" ]]
}

is_arch_like() {
    [[ -r /etc/os-release ]] || return 1
    . /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
        *arch*|*endeavouros*) return 0 ;;
    esac
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

resolve_profile() {
    local detected answer
    [[ "$profile" == "auto" ]] || return 0
    detected="$(detect_machine_profile || true)"
    if [[ -n "$detected" ]]; then
        profile="$detected"
        log "Detected profile: $profile"
        return 0
    fi
    if [[ "$dry_run" == "1" || "$no_prompt" == "1" || "$assume_yes" == "1" ]]; then
        profile="laptop-light"
        log "Could not detect hardware profile; defaulting to laptop-light"
        return 0
    fi
    printf 'Could not detect laptop vs desktop. Use laptop-light? [Y/n] ' >&2
    read -r answer
    case "$answer" in
        n|N|no|NO) profile="desktop" ;;
        *) profile="laptop-light" ;;
    esac
}

hyde_detected() {
    command -v hyde-shell >/dev/null 2>&1 && return 0
    command -v hydectl >/dev/null 2>&1 && return 0
    [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/hyde" ]] && return 0
    return 1
}

install_prerequisites() {
    stage_done preflight && { log "Stage preflight already complete."; return 0; }
    command -v pacman >/dev/null 2>&1 || {
        printf 'pacman is required. This installer supports Arch/EndeavourOS-style systems only.\n' >&2
        exit 1
    }
    command -v sudo >/dev/null 2>&1 || {
        printf 'sudo is required for package and boot/login-manager setup.\n' >&2
        exit 1
    }
    if [[ "$dry_run" != "1" ]]; then
        sudo -v
    fi
    run sudo pacman -S --needed --noconfirm git base-devel curl rsync jq tar
    mark_stage preflight
}

clone_or_update_collection() {
    stage_done collection && { log "Stage collection already complete."; return 0; }
    if [[ -d "$repo_dir/.git" ]]; then
        run git -C "$repo_dir" pull --ff-only
    elif [[ -d "$repo_dir/$theme_rel" ]]; then
        log "Using local MADPANDA theme collection: $repo_dir"
    elif [[ -e "$repo_dir" && -n "$(find "$repo_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
        printf 'Target repo directory exists but is not a MADPANDA theme collection: %s\n' "$repo_dir" >&2
        exit 1
    else
        run mkdir -p "$(dirname "$repo_dir")"
        run git clone --depth 1 "$repo_url" "$repo_dir"
    fi
    if [[ -d "$repo_dir/.git" && "$(command -v git-lfs || true)" ]]; then
        run git -C "$repo_dir" lfs pull
    fi
    mark_stage collection
}

resume_command() {
    local args=(--resume --profile "$profile")
    [[ "$assume_yes" == "1" ]] && args+=(--yes)
    [[ "$no_prompt" == "1" ]] && args+=(--no-prompt)
    [[ -n "$enable_csv" ]] && args+=(--enable "$enable_csv")
    [[ -n "$disable_csv" ]] && args+=(--disable "$disable_csv")
    printf '%q ' "$repo_dir/install.sh" "${args[@]}"
}

strip_resume_hook() {
    local file="$1"
    awk -v start="$resume_start" -v end="$resume_end" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$file"
}

install_resume_hook() {
    local command tmp
    command="$(resume_command)"
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] install Hyprland resume hook in %q\n' "$hyprland_conf"
        printf '%s\nexec-once = bash -lc %q\n%s\n' "$resume_start" "$command" "$resume_end"
        return 0
    fi
    mkdir -p "$(dirname "$hyprland_conf")"
    touch "$hyprland_conf"
    tmp="$(mktemp)"
    strip_resume_hook "$hyprland_conf" >"$tmp"
    {
        cat "$tmp"
        printf '\n%s\n' "$resume_start"
        printf 'exec-once = bash -lc %q\n' "$command"
        printf '%s\n' "$resume_end"
    } >"$hyprland_conf"
    rm -f "$tmp"
    log "Installed one-shot Hyprland resume hook: $hyprland_conf"
}

remove_resume_hook() {
    local tmp
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] remove Hyprland resume hook from %q\n' "$hyprland_conf"
        return 0
    fi
    [[ -r "$hyprland_conf" ]] || return 0
    tmp="$(mktemp)"
    strip_resume_hook "$hyprland_conf" >"$tmp"
    install -m 0644 "$tmp" "$hyprland_conf"
    rm -f "$tmp"
    rm -f "$resume_attempt_file"
    log "Removed Dark Zen resume hook."
}

check_resume_guard() {
    local attempts=0
    [[ "$resume" == "1" ]] || return 0
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] increment resume attempt guard\n'
        return 0
    fi
    [[ -r "$resume_attempt_file" ]] && attempts="$(cat "$resume_attempt_file" 2>/dev/null || printf 0)"
    attempts=$((attempts + 1))
    printf '%s\n' "$attempts" >"$resume_attempt_file"
    if ((attempts > 3)); then
        remove_resume_hook
        printf 'Dark Zen resume attempted more than 3 times; removed hook to avoid a loop.\n' >&2
        exit 1
    fi
}

install_hyde_if_needed() {
    if hyde_detected; then
        log "HyDE detected; official HyDE installer will not run."
        mark_stage hyde
        return 0
    fi
    if [[ "$skip_hyde" == "1" ]]; then
        printf 'HyDE is missing and --skip-hyde was set. Install HyDE first, then rerun this script.\n' >&2
        exit 1
    fi

    cat >&2 <<'EOF'

HyDE is not detected.
Dark Zen is a HyDE theme, so the official HyDE installer is required first.

Important:
- HyDE must run as your normal user, not with sudo.
- HyDE may change GTK/Qt theming, shell config, SDDM, NVIDIA settings, and boot config.
- This installer will pause for a reboot before applying Dark Zen.

EOF
    if [[ "$(ask_yes_no 'Install official HyDE now?' 1)" != "1" ]]; then
        printf 'HyDE install declined. Bootstrap stopped before applying Dark Zen.\n' >&2
        exit 1
    fi

    if [[ -d "$hyde_dir/.git" ]]; then
        run git -C "$hyde_dir" pull --ff-only
    elif [[ -e "$hyde_dir" ]]; then
        printf 'HyDE target exists but is not a Git checkout: %s\n' "$hyde_dir" >&2
        exit 1
    else
        run git clone --depth 1 https://github.com/HyDE-Project/HyDE "$hyde_dir"
    fi

    run_logged "$log_dir/hyde-install.log" bash -lc "cd \"\$1/Scripts\" && ./install.sh" bash "$hyde_dir"
    mark_stage hyde
    install_resume_hook

    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] would stop after HyDE and request reboot before Dark Zen apply\n'
        return 0
    fi

    if [[ "$no_prompt" == "1" ]]; then
        printf 'HyDE finished. Reboot, then log into Hyprland; Dark Zen will resume automatically.\n'
        exit 0
    fi
    if [[ "$(ask_yes_no 'Reboot now so Dark Zen can resume cleanly after HyDE?' 1)" == "1" ]]; then
        run systemctl reboot
    else
        printf 'Reboot when ready, then log into Hyprland; Dark Zen will resume automatically.\n'
    fi
    exit 0
}

theme_asset_dir_exists() {
    local kind="$1"
    local name="$2"
    local base
    case "$kind" in
        theme)
            for base in "${XDG_DATA_HOME:-$HOME/.local/share}/themes" "$HOME/.themes" /usr/share/themes; do
                [[ -d "$base/$name" ]] && return 0
            done
            ;;
        icon)
            for base in "${XDG_DATA_HOME:-$HOME/.local/share}/icons" "$HOME/.icons" /usr/share/icons; do
                [[ -d "$base/$name" ]] && return 0
            done
            ;;
    esac
    return 1
}

install_source_assets() {
    local source_dir="$1"
    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    local archive found=0

    [[ -d "$source_dir" ]] || {
        printf 'Dark Zen Source assets are missing: %s\n' "$source_dir" >&2
        exit 1
    }

    for archive in "$source_dir"/Gtk_*.tar.gz; do
        [[ -r "$archive" ]] || continue
        found=1
        if [[ "$dry_run" == "1" ]]; then
            printf '[dry-run] tar -xzf %q -C %q\n' "$archive" "$data_home/themes"
        else
            mkdir -p "$data_home/themes"
            tar -xzf "$archive" -C "$data_home/themes"
        fi
    done
    for archive in "$source_dir"/Icon_*.tar.gz "$source_dir"/Cursor_*.tar.gz; do
        [[ -r "$archive" ]] || continue
        found=1
        if [[ "$dry_run" == "1" ]]; then
            printf '[dry-run] tar -xzf %q -C %q\n' "$archive" "$data_home/icons"
        else
            mkdir -p "$data_home/icons"
            tar -xzf "$archive" -C "$data_home/icons"
        fi
    done

    [[ "$found" == "1" ]] || {
        printf 'No GTK/Icon/Cursor archives found under %s\n' "$source_dir" >&2
        exit 1
    }
}

verify_installed_assets() {
    [[ "$dry_run" == "1" ]] && { printf '[dry-run] verify installed Dark Zen GTK/Icon/Cursor assets\n'; return 0; }
    theme_asset_dir_exists theme MADPANDA-Dark-Zen || { printf 'Missing GTK theme: MADPANDA-Dark-Zen\n' >&2; exit 1; }
    theme_asset_dir_exists icon besgnulinux-mono-red || { printf 'Missing icon theme: besgnulinux-mono-red\n' >&2; exit 1; }
    theme_asset_dir_exists icon Night-Diamond-Red || { printf 'Missing cursor theme: Night-Diamond-Red\n' >&2; exit 1; }
}

disable_uwsm_session() {
    local session="/usr/share/wayland-sessions/hyprland-uwsm.desktop"
    local disabled="$session.disabled-by-madpanda"
    [[ -e "$session" ]] || return 0
    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] sudo mv %q %q\n' "$session" "$disabled"
        return 0
    fi
    run sudo mv "$session" "$disabled"
}

import_dark_zen() {
    local theme_pkg="$repo_dir/$theme_rel"
    local configs="$theme_pkg/Configs"
    local source_dir="$theme_pkg/Source"
    local source_theme="$configs/.config/hyde/themes/$theme_name"
    local live_theme="${XDG_CONFIG_HOME:-$HOME/.config}/hyde/themes/$theme_name"
    local theme_installer
    local installer_args=(--profile "$profile")

    stage_done dark-zen && { log "Stage dark-zen already complete."; return 0; }

    if [[ ! -d "$source_theme" ]]; then
        if [[ "$dry_run" == "1" ]]; then
            log "Dark Zen package is not present yet; dry-run assumes it exists after clone: $source_theme"
        else
            printf 'Dark Zen package not found at %s\n' "$source_theme" >&2
            exit 1
        fi
    fi

    install_source_assets "$source_dir"

    if command -v hydectl >/dev/null 2>&1; then
        run_logged "$log_dir/dark-zen-import.log" hydectl theme import --name "$theme_name" --url "$theme_pkg" || {
            log "hydectl import failed; falling back to direct rsync."
            run mkdir -p "$live_theme"
            run rsync -a --delete "$source_theme/" "$live_theme/"
        }
    else
        log "hydectl not found; using direct rsync import."
        run mkdir -p "$live_theme"
        run rsync -a --delete "$source_theme/" "$live_theme/"
    fi

    verify_installed_assets
    disable_uwsm_session

    theme_installer="$live_theme/install.sh"
    if [[ "$dry_run" == "1" && ! -r "$theme_installer" ]]; then
        theme_installer="$source_theme/install.sh"
    fi
    if [[ ! -r "$theme_installer" ]]; then
        printf 'Dark Zen installer was not found after import: %s/install.sh\n' "$live_theme" >&2
        exit 1
    fi

    [[ "$dry_run" == "1" ]] && installer_args+=(--dry-run)
    [[ "$assume_yes" == "1" ]] && installer_args+=(--yes)
    [[ "$no_prompt" == "1" ]] && installer_args+=(--no-prompt)
    [[ -n "$enable_csv" ]] && installer_args+=(--enable "$enable_csv")
    [[ -n "$disable_csv" ]] && installer_args+=(--disable "$disable_csv")
    run_logged "$log_dir/dark-zen-install.log" bash "$theme_installer" "${installer_args[@]}"

    if [[ "$dry_run" == "1" ]]; then
        printf '[dry-run] hyde-shell theme.switch -q -s %q\n' "$theme_name"
    else
        command -v hyde-shell >/dev/null 2>&1 || {
            printf 'hyde-shell is required to activate %s.\n' "$theme_name" >&2
            exit 1
        }
        run hyde-shell theme.switch -q -s "$theme_name"
    fi
    mark_stage dark-zen
}

final_checks() {
    if command -v mad-theme-pack >/dev/null 2>&1; then
        run mad-theme-pack status "$theme_name" || true
    else
        log "mad-theme-pack is not available yet; status check skipped."
    fi
    if command -v hyprctl >/dev/null 2>&1; then
        run hyprctl configerrors || true
    else
        log "hyprctl is not available in this shell; Hyprland config check skipped."
    fi
}

main() {
    if [[ "${EUID:-$(id -u)}" == "0" ]]; then
        printf 'Do not run this bootstrap as root. Run it as your normal user.\n' >&2
        exit 1
    fi
    if ! is_arch_like; then
        printf 'This installer targets EndeavourOS/Arch-like systems.\n' >&2
        exit 1
    fi

    resolve_profile
    check_resume_guard
    log "Bootstrap profile: $profile"
    log "Evidence root: $run_root"

    install_prerequisites
    clone_or_update_collection
    install_hyde_if_needed
    import_dark_zen
    final_checks
    remove_resume_hook
    mark_stage complete

    printf 'MADPANDA Dark Zen bootstrap finished. Profile: %s\n' "$profile"
    printf 'Logs: %s\n' "$run_root"
}

main "$@"
