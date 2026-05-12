#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/madpanda/eww-widgets"
state_file="$state_dir/calendar.env"
scripts="${XDG_CONFIG_HOME:-$HOME/.config}/madpanda/eww-testbar/MADPANDA-Dark-Zen/scripts"
offset="0"

if [[ -r "$state_file" ]]; then
    offset="$(sed -n 's/^MAD_EWW_CALENDAR_OFFSET=//p' "$state_file" | tail -n 1)"
fi
[[ "$offset" =~ ^-?[0-9]+$ ]] || offset="0"

target_date="$(date -d "$(date +%Y-%m-01) ${offset} month" +%Y-%m-01)"
year="$(date -d "$target_date" +%Y)"
month="$(date -d "$target_date" +%m)"
today="$(date +%d)"
current_year="$(date +%Y)"
current_month="$(date +%m)"
month_name="$(date -d "$target_date" +%B)"
first_day="$(date -d "$target_date" +%u)"
days_in_month="$(date -d "$target_date +1 month -1 day" +%d)"

printf '(box :orientation "vertical" :class "drawer-calendar-inner"\n'
printf '  (box :orientation "horizontal" :class "calendar-nav" :space-evenly false\n'
printf '    (button :class "calendar-nav-button" :tooltip "Previous month" :onclick "%s/calendar-action.sh previous" "‹")\n' "$scripts"
printf '    (label :class "drawer-title calendar-title" :text "%s %s")\n' "$month_name" "$year"
printf '    (button :class "calendar-nav-button today-button" :tooltip "Current month" :onclick "%s/calendar-action.sh today" "Today")\n' "$scripts"
printf '    (button :class "calendar-nav-button" :tooltip "Next month" :onclick "%s/calendar-action.sh next" "›")\n' "$scripts"
printf '  )\n'
printf '  (box :orientation "horizontal" :class "drawer-weekdays"\n'
for day in Mon Tue Wed Thu Fri Sat Sun; do
    printf '    (label :class "drawer-weekday" :text "%s")\n' "$day"
done
printf '  )\n'

count=1
row='  (box :orientation "horizontal" :class "drawer-calendar-row"'

for ((i = 1; i < first_day; i++)); do
    row="$row (label :class \"drawer-day empty\" :text \" \")"
    count=$((count + 1))
done

for ((d = 1; d <= days_in_month; d++)); do
    text="$(printf '%2d' "$d")"
    class="drawer-day"
    if [[ "$year" == "$current_year" && "$month" == "$current_month" && "$d" -eq "$((10#$today))" ]]; then
        class="drawer-day today"
    fi
    row="$row (label :class \"$class\" :text \"$text\")"

    if ((count % 7 == 0)); then
        printf '%s)\n' "$row"
        row='  (box :orientation "horizontal" :class "drawer-calendar-row"'
    fi
    count=$((count + 1))
done

remaining=$(((count - 1) % 7))
if ((remaining != 0)); then
    for ((i = remaining; i < 7; i++)); do
        row="$row (label :class \"drawer-day empty\" :text \" \")"
    done
    printf '%s)\n' "$row"
fi
printf ')\n'
