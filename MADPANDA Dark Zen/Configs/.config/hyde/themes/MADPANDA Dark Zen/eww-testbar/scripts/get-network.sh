#!/usr/bin/env bash
set -euo pipefail

connection="$(nmcli -t -f TYPE,STATE,DEVICE device 2>/dev/null | awk -F: '$2=="connected" {print $1 ":" $3; exit}')"
case "$connection" in
    wifi:*)
        nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes" {print $2; found=1; exit} END {if (!found) print "Wi-Fi"}'
        ;;
    ethernet:*)
        printf '%s\n' "${connection#ethernet:}"
        ;;
    *)
        printf 'Offline\n'
        ;;
esac
