#!/bin/bash
# Prepends mouse (hidpp) and bluetooth keyboard battery to i3status output.

CACHE=/tmp/.bt_batt_cache

get_batt() {
    # refresh cache at most every 60s
    if [[ ! -f $CACHE ]] || (( $(date +%s) - $(stat -c %Y "$CACHE") >= 60 )); then
        M=$(upower -i /org/freedesktop/UPower/devices/battery_hidpp_battery_0 2>/dev/null \
            | awk '/percentage/ {print substr($2,1,length($2)-1); exit}')
        K=$(upower -i /org/freedesktop/UPower/devices/keyboard_dev_CA_D7_58_04_03_34 2>/dev/null \
            | awk '/percentage/ {print substr($2,1,length($2)-1); exit}')
        printf 'm:%s%% k:%s%%' "${M:-?}" "${K:-?}" > "$CACHE"
    fi
    cat "$CACHE"
}

# prepend our segment to each i3status line
i3status | while :; do
    read -r line
    printf '%s | %s\n' "$(get_batt)" "$line"
done
