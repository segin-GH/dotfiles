#!/bin/bash
# wifi_menu.sh - pick and connect to a Wi-Fi network using dmenu.

DMENU_OPTS=(-i -p "Wi-Fi" -nb '#1f222d' -nf '#81a1c1' -sb '#81a1c1' -sf '#1f222d' -fn 'OperatorMonoBook:bold:pixelsize=12')

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Wi-Fi" "$1" "$2"
}

list=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>/dev/null |
    awk -F: '
        $2 == "" { next }
        { if (seen[$2]++) next
          mark = ($1 == "*") ? "* " : ""
          printf "%s%s\t(%s%%) %s\n", mark, $2, $3, $4 }')

selection=$(printf '%s\n' "$list" | dmenu "${DMENU_OPTS[@]}")
[ -z "$selection" ] && exit 0

ssid=$(printf '%s' "$selection" | sed -E 's/^\* //; s/\t.*$//')
[ -z "$ssid" ] && exit 0

if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
    if nmcli connection up "$ssid" >/dev/null 2>&1; then
        notify "Connected" "$ssid"
    else
        notify "Failed" "Could not connect to $ssid"
    fi
else
    password=$(dmenu "${DMENU_OPTS[@]}" -p "$ssid password" </dev/null)
    [ -z "$password" ] && exit 0
    if nmcli dev wifi connect "$ssid" password "$password" >/dev/null 2>&1; then
        notify "Connected" "$ssid"
    else
        notify "Failed" "Could not connect to $ssid"
    fi
fi
