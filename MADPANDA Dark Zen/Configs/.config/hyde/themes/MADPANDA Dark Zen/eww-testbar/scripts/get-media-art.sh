#!/usr/bin/env bash
set -euo pipefail

scripts="$HOME/.config/madpanda/eww-testbar/MADPANDA-Dark-Zen/scripts"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/madpanda/eww-media"
mkdir -p "$cache_dir"

image_markup() {
    local path="$1"
    if [[ -n "$path" && -r "$path" ]]; then
        path="${path//\\/\\\\}"
        path="${path//\"/\\\"}"
        printf '(image :class "media-art-image" :path "%s" :image-width 76 :image-height 76)\n' "$path"
        return 0
    fi
    return 1
}

fallback_markup() {
    printf '(box :class "media-art-fallback" :orientation "horizontal" (label :class "media-art-icon" :text "󰝚"))\n'
}

pandora_art="$("$scripts/get-pandora-cache-field.sh" artPath 2>/dev/null || true)"
image_markup "$pandora_art" && exit 0

art_url=""
if command -v playerctl >/dev/null 2>&1; then
    art_url="$(timeout 1.5s playerctl metadata mpris:artUrl 2>/dev/null || true)"
fi

if [[ "$art_url" == file://* ]]; then
    image_markup "${art_url#file://}" && exit 0
elif [[ "$art_url" == http://* || "$art_url" == https://* ]]; then
    digest="$(printf '%s' "$art_url" | sha256sum | awk '{print $1}')"
    target="$cache_dir/mpris-${digest:0:24}.jpg"
    if [[ ! -s "$target" ]] && command -v curl >/dev/null 2>&1; then
        curl -fsSL --max-time 8 "$art_url" -o "$target" 2>/dev/null || rm -f "$target"
    fi
    image_markup "$target" && exit 0
fi

fallback_markup
