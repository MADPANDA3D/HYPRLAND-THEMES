#!/usr/bin/env bash
set -euo pipefail

type="$(nmcli -t -f TYPE,STATE device 2>/dev/null | awk -F: '$2=="connected" {print $1; exit}')"
case "$type" in
    ethernet)
        printf '󰈀\n'
        ;;
    wifi)
        signal="$(nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk '$1=="*" {print $2; exit}')"
        signal="${signal:-0}"
        if (( signal >= 75 )); then
            printf '󰤨\n'
        elif (( signal >= 50 )); then
            printf '󰤥\n'
        elif (( signal >= 25 )); then
            printf '󰤢\n'
        else
            printf '󰤟\n'
        fi
        ;;
    *)
        printf '󰤭\n'
        ;;
esac
