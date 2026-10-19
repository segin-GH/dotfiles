#!/bin/sh
# launch-or-focus.sh - run an app, or focus it if it is already running.
#
# usage: launch-or-focus.sh <wm-class> <workspace> <command> [args...]
#
# If a window with WM_CLASS == <wm-class> already exists, focus that window
# (i3 switches to whatever workspace it lives on). Otherwise switch to
# <workspace> and launch <command>.

set -eu

class="$1"
shift
workspace="$1"
shift

if i3-msg -t get_tree |
    jq -e --arg c "$class" \
        '.. | objects | select(.window_properties?.class? == $c)' >/dev/null 2>&1; then
    i3-msg "[class=\"^${class}\$\"] focus" >/dev/null
else
    i3-msg "workspace number ${workspace}" >/dev/null
    exec "$@"
fi
