#!/usr/bin/env bash
set -euo pipefail

repo_url="${MADPANDA_HYPRLAND_THEMES_REPO:-https://github.com/MADPANDA3D/HYPRLAND-THEMES.git}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd || true)"
if [[ -n "${MADPANDA_HYPRLAND_THEMES_DIR:-}" ]]; then
    repo_dir="$MADPANDA_HYPRLAND_THEMES_DIR"
elif [[ -n "$script_dir" && -d "$script_dir/.git" && -d "$script_dir/MADPANDA Dark Zen" ]]; then
    repo_dir="$script_dir"
else
    repo_dir="$HOME/.local/share/madpanda/hyprland-themes"
fi
theme_name="MADPANDA Dark Zen"
theme_rel="MADPANDA Dark Zen"
theme_config_rel="Configs/.config/hyde/themes/MADPANDA Dark Zen"
hyde_dir="${MADPANDA_HYDE_DIR:-$HOME/HyDE}"
run_id="$(date +%Y%m%dT%H%M%S%z)-$$"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/madpanda/bootstrap/$run_id"
log_dir="$state_root/logs"
dry_run="0"
assume_yes="0"
no_prompt="0"
profile="auto"
skip_hyde="0"

usage() {
    cat <<'EOF'
Usage:
  install.sh [--dry-run] [--yes] [--no-prompt] [--profile auto|desktop|laptop-light] [--skip-hyde]

One-command bootstrap for MADPANDA Hyprland themes on Arch/EndeavourOS.
It installs prerequisites, installs official HyDE if missing, imports
MADPANDA Dark Zen, then runs the theme's guided installer.
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) dry_run="1" ;;
        --yes|-y) assume_yes="1" ;;
        --no-prompt) no_prompt="1" ;;
        --profile)
            shift
            profile="${1:-auto}"
            ;;
        --skip-hyde) skip_hyde="1" ;;
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

mkdir -p "$log_dir"

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
    command -v pacman >/dev/null 2>&1 || {
        printf 'pacman is required. This installer supports Arch/EndeavourOS-style systems only.\n' >&2
        exit 1
    }
    command -v sudo >/dev/null 2>&1 || {
        printf 'sudo is required for package installation.\n' >&2
        exit 1
    }
    if [[ "$dry_run" != "1" ]]; then
        sudo -v
    fi
    run sudo pacman -S --needed git base-devel curl rsync jq
}

clone_or_update_collection() {
    if [[ -d "$repo_dir/.git" ]]; then
        run git -C "$repo_dir" pull --ff-only
        return 0
    fi
    if [[ -e "$repo_dir" && -n "$(find "$repo_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
        printf 'Target repo directory exists but is not a Git checkout: %s\n' "$repo_dir" >&2
        exit 1
    fi
    run mkdir -p "$(dirname "$repo_dir")"
    run git clone --depth 1 "$repo_url" "$repo_dir"
    if command -v git-lfs >/dev/null 2>&1; then
        run git -C "$repo_dir" lfs pull
    fi
}

install_hyde_if_needed() {
    if hyde_detected; then
        log "HyDE detected; official HyDE installer will not run."
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
- Logs will be captured under ~/.local/state/madpanda/bootstrap/.

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

    if [[ "${EUID:-$(id -u)}" == "0" ]]; then
        printf 'Refusing to run HyDE as root.\n' >&2
        exit 1
    fi
    run_logged "$log_dir/hyde-install.log" bash -lc "cd \"\$1/Scripts\" && ./install.sh" bash "$hyde_dir"
}

import_dark_zen() {
    local theme_pkg="$repo_dir/$theme_rel"
    local configs="$theme_pkg/Configs"
    local source_theme="$configs/.config/hyde/themes/$theme_name"
    local live_theme="${XDG_CONFIG_HOME:-$HOME/.config}/hyde/themes/$theme_name"

    [[ -d "$source_theme" ]] || {
        printf 'Dark Zen package not found at %s\n' "$source_theme" >&2
        exit 1
    }

    if command -v hydectl >/dev/null 2>&1; then
        run_logged "$log_dir/dark-zen-import.log" hydectl theme import --name "$theme_name" --url "$configs" || {
            log "hydectl import failed; falling back to direct rsync."
            run mkdir -p "$live_theme"
            run rsync -a --delete "$source_theme/" "$live_theme/"
        }
    else
        log "hydectl not found; using direct rsync import."
        run mkdir -p "$live_theme"
        run rsync -a --delete "$source_theme/" "$live_theme/"
    fi

    local theme_installer="$live_theme/install.sh"
    if [[ "$dry_run" == "1" && ! -r "$theme_installer" ]]; then
        theme_installer="$source_theme/install.sh"
    fi
    if [[ ! -r "$theme_installer" ]]; then
        printf 'Dark Zen installer was not found after import: %s/install.sh\n' "$live_theme" >&2
        exit 1
    fi

    local installer_args=(--profile "$profile")
    [[ "$dry_run" == "1" ]] && installer_args+=(--dry-run)
    [[ "$assume_yes" == "1" ]] && installer_args+=(--yes)
    [[ "$no_prompt" == "1" ]] && installer_args+=(--no-prompt)
    run_logged "$log_dir/dark-zen-install.log" bash "$theme_installer" "${installer_args[@]}"
}

final_checks() {
    if command -v mad-theme-pack >/dev/null 2>&1; then
        run mad-theme-pack status "$theme_name"
    else
        log "mad-theme-pack is not available yet; status check skipped."
    fi
    if command -v hyprctl >/dev/null 2>&1; then
        run hyprctl configerrors
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
    log "Bootstrap profile: $profile"
    log "Evidence/log root: $state_root"

    install_prerequisites
    clone_or_update_collection
    install_hyde_if_needed
    import_dark_zen
    final_checks

    printf 'MADPANDA Dark Zen bootstrap finished. Profile: %s\n' "$profile"
    printf 'Logs: %s\n' "$state_root"
}

main "$@"
